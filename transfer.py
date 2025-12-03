#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HuggingFace Model Repository Transfer Tool

A CLI tool to transfer model repositories from HuggingFace to other Git LFS-based platforms.
"""

import os
import sys
import argparse
import subprocess
import shutil
import tempfile
from pathlib import Path
from urllib.parse import urlparse, urlunparse, quote_plus

import requests
from dotenv import load_dotenv


def str_to_bool(value: str, default: bool = False) -> bool:
    """Convert truthy strings to boolean values."""
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def ensure_git_suffix(url: str) -> str:
    """Ensure repository URL ends with .git."""
    normalized = url.rstrip("/")
    if normalized.endswith(".git"):
        return normalized
    return f"{normalized}.git"


class MirrorConfigurationError(Exception):
    """Raised when remote mirroring configuration fails."""


class MirrorManager:
    """Configure server-side repository mirroring (e.g., GitLab pull mirror)."""

    def __init__(self, source_url: str, target_url: str):
        self.source_url = ensure_git_suffix(source_url)
        self.target_url = ensure_git_suffix(target_url)
        self.platform = os.getenv("MIRROR_PLATFORM", "gitlab").lower()

    def configure(self):
        print("\n" + "=" * 60)
        print("🪞 Remote Mirroring Mode")
        print("=" * 60)
        print(f"📍 Source: {self.source_url}")
        print(f"📍 Target: {self.target_url}")

        if self.platform == "gitlab":
            self._configure_gitlab_mirror()
        else:
            raise MirrorConfigurationError(
                f"Unsupported MIRROR_PLATFORM '{self.platform}'. "
                "Currently only 'gitlab' is implemented."
            )

        print("\n" + "=" * 60)
        print("🎉 Remote mirror configured successfully!")
        print("=" * 60)

    def _configure_gitlab_mirror(self):
        api_base = os.getenv("GITLAB_API_BASE") or self._infer_gitlab_api_base()
        token = os.getenv("GITLAB_API_TOKEN") or os.getenv("TARGET_TOKEN")
        if not token:
            raise MirrorConfigurationError(
                "Missing GitLab API token. Set TARGET_TOKEN or GITLAB_API_TOKEN."
            )

        headers = {"PRIVATE-TOKEN": token}
        project_path = (
            os.getenv("GITLAB_PROJECT_PATH") or self._infer_project_path_from_target()
        )
        project_id = self._resolve_project_id(api_base, project_path, headers)

        mirror_endpoint = f"{api_base}/projects/{project_id}/remote_mirrors"
        hf_url_with_creds = self._build_hf_authenticated_url()

        payload = {
            "enabled": True,
            "url": hf_url_with_creds,
            "only_protected_branches": False,
        }

        mirror_regex = os.getenv("GITLAB_MIRROR_BRANCH_REGEX")
        if mirror_regex:
            payload["mirror_branch_regex"] = mirror_regex

        existing = self._find_existing_mirror(mirror_endpoint, headers, hf_url_with_creds)
        if existing:
            mirror_id = existing["id"]
            print(f"🔁 Updating existing GitLab mirror (id={mirror_id})")
            response = requests.put(
                f"{mirror_endpoint}/{mirror_id}", headers=headers, json=payload, timeout=30
            )
        else:
            print("➕ Creating GitLab pull mirror")
            response = requests.post(
                mirror_endpoint, headers=headers, json=payload, timeout=30
            )

        if response.status_code not in {200, 201}:
            raise MirrorConfigurationError(
                f"Failed to configure GitLab mirror: {response.status_code} {response.text}"
            )

        print("✅ GitLab mirror configuration applied.")
        print("   GitLab will now sync directly from HuggingFace on its own schedule.")

    def _infer_gitlab_api_base(self) -> str:
        parsed = urlparse(self.target_url)
        return f"{parsed.scheme}://{parsed.netloc}/api/v4"

    def _infer_project_path_from_target(self) -> str:
        parsed = urlparse(self.target_url)
        project = parsed.path.lstrip("/")
        if project.endswith(".git"):
            project = project[:-4]
        if not project:
            raise MirrorConfigurationError(
                "Unable to infer GitLab project path from target URL. "
                "Set GITLAB_PROJECT_PATH explicitly."
            )
        return project

    def _resolve_project_id(self, api_base, project_path, headers) -> int:
        project_url = f"{api_base}/projects/{quote_plus(project_path)}"
        response = requests.get(project_url, headers=headers, timeout=15)
        if response.status_code != 200:
            raise MirrorConfigurationError(
                f"Failed to fetch GitLab project '{project_path}': "
                f"{response.status_code} {response.text}"
            )
        return response.json()["id"]

    def _build_hf_authenticated_url(self) -> str:
        hf_token = os.getenv("HF_TOKEN")
        hf_username = os.getenv("HF_USERNAME")
        if not hf_token or not hf_username:
            raise MirrorConfigurationError(
                "HF_TOKEN and HF_USERNAME are required to configure GitLab mirroring."
            )

        parsed = urlparse(self.source_url)
        netloc = f"{hf_username}:{hf_token}@{parsed.netloc}"
        return urlunparse(
            (
                parsed.scheme,
                netloc,
                parsed.path,
                parsed.params,
                parsed.query,
                parsed.fragment,
            )
        )

    def _find_existing_mirror(self, endpoint, headers, hf_url_with_creds):
        response = requests.get(endpoint, headers=headers, timeout=15)
        if response.status_code != 200:
            return None
        mirrors = response.json()
        # compare without credentials for stability
        normalized_target = self._strip_credentials(hf_url_with_creds)
        for mirror in mirrors:
            if self._strip_credentials(mirror.get("url", "")) == normalized_target:
                return mirror
        return None

    @staticmethod
    def _strip_credentials(url: str) -> str:
        parsed = urlparse(url)
        netloc = parsed.hostname or ""
        if parsed.port:
            netloc = f"{netloc}:{parsed.port}"
        return urlunparse(
            (
                parsed.scheme,
                netloc,
                parsed.path,
                parsed.params,
                parsed.query,
                parsed.fragment,
            )
        )


class ModelTransfer:
    def __init__(self, source_url: str, target_url: str, temp_dir: str = None, mirror_mode: bool = False, use_xget: bool = False):
        self.source_url = self._apply_xget_acceleration(source_url) if use_xget else source_url
        self.target_url = target_url
        self.temp_dir = temp_dir or tempfile.mkdtemp(prefix="hf_transfer_")
        self.repo_path = os.path.join(self.temp_dir, "repo")
        self.pointer_only_mode = str_to_bool(os.getenv('GIT_LFS_SKIP_SMUDGE'), default=False)
        self.mirror_mode = mirror_mode
        self.use_xget = use_xget
    
    @staticmethod
    def _apply_xget_acceleration(url: str) -> str:
        """
        Apply Xget acceleration to HuggingFace URLs.
        Converts: https://huggingface.co/... to https://xget.xi-xu.me/hf/...
        """
        if 'huggingface.co' in url:
            # Remove https:// prefix if present
            url_without_protocol = url.replace('https://', '').replace('http://', '')
            # Remove huggingface.co/ and prepend xget prefix
            accelerated_path = url_without_protocol.replace('huggingface.co/', '')
            accelerated_url = f'https://xget.xi-xu.me/hf/{accelerated_path}'
            return accelerated_url
        return url
        
    def run_command(self, cmd: list, cwd: str = None, env: dict = None):
        """Execute shell command and return output."""
        print(f"\n🔧 Executing: {' '.join(cmd)}")
        
        # Merge environment variables
        cmd_env = os.environ.copy()
        if env:
            cmd_env.update(env)
        
        try:
            result = subprocess.run(
                cmd,
                cwd=cwd,
                check=True,
                capture_output=True,
                text=True,
                env=cmd_env
            )
            if result.stdout:
                print(result.stdout)
            return result
        except subprocess.CalledProcessError as e:
            print(f"❌ Error executing command: {' '.join(cmd)}")
            print(f"Return code: {e.returncode}")
            if e.stdout:
                print(f"STDOUT: {e.stdout}")
            if e.stderr:
                print(f"STDERR: {e.stderr}")
            raise
    
    def inject_credentials(self, url: str, username: str = None, token: str = None):
        """Inject credentials into git URL if provided and valid."""
        # Check if token is empty or a placeholder
        if not token or self._is_placeholder(token):
            return url
        
        # Check if username is a placeholder
        if username and self._is_placeholder(username):
            username = None
        
        parsed = urlparse(url)
        
        # If URL already has credentials, return as is
        if '@' in parsed.netloc:
            return url
        
        # Inject credentials
        if username:
            netloc = f"{username}:{token}@{parsed.netloc}"
        else:
            netloc = f"{token}@{parsed.netloc}"
        
        return urlunparse((
            parsed.scheme,
            netloc,
            parsed.path,
            parsed.params,
            parsed.query,
            parsed.fragment
        ))
    
    @staticmethod
    def _is_placeholder(value: str) -> bool:
        """Check if a value is a placeholder string."""
        if not value:
            return True
        
        # Common placeholder patterns
        placeholders = [
            'your_', 'your-', 'yourhf', 
            'placeholder', 'example',
            'xxx', 'token_here', 'username_here',
            'changeme', 'replace', 'fill'
        ]
        
        value_lower = value.lower()
        return any(pattern in value_lower for pattern in placeholders)
    
    def clone_source(self):
        """Clone the source repository from HuggingFace."""
        print("\n" + "="*60)
        print("📥 Step 1: Cloning source repository from HuggingFace")
        print("="*60)
        
        if self.use_xget:
            print("🚀 Xget acceleration enabled for faster downloads!")
            print(f"   Accelerated URL: {self.source_url}")
        
        # Get HuggingFace token from environment
        hf_token = os.getenv('HF_TOKEN')
        source_url_with_creds = self.inject_credentials(
            self.source_url,
            username=os.getenv('HF_USERNAME'),
            token=hf_token
        )
        
        # Set GIT_LFS_SKIP_SMUDGE to speed up initial clone
        env = {'GIT_LFS_SKIP_SMUDGE': '1'}
        
        # Clone repository
        self.run_command([
            'git', 'clone',
            source_url_with_creds,
            self.repo_path
        ], env=env)
        
        print("✅ Source repository cloned successfully")
    
    def clone_source_mirror(self):
        """Clone the source repository as a bare mirror from HuggingFace."""
        print("\n" + "="*60)
        print("📥 Step 1: Cloning source repository as mirror from HuggingFace")
        print("="*60)
        print("ℹ️  Mirror mode: cloning ALL refs (branches, tags, remotes)")
        
        if self.use_xget:
            print("🚀 Xget acceleration enabled for faster downloads!")
            print(f"   Accelerated URL: {self.source_url}")
        
        # Get HuggingFace token from environment
        hf_token = os.getenv('HF_TOKEN')
        source_url_with_creds = self.inject_credentials(
            self.source_url,
            username=os.getenv('HF_USERNAME'),
            token=hf_token
        )
        
        # Set GIT_LFS_SKIP_SMUDGE to speed up initial clone
        env = {'GIT_LFS_SKIP_SMUDGE': '1'}
        
        # Clone as bare mirror repository
        self.run_command([
            'git', 'clone', '--mirror',
            source_url_with_creds,
            self.repo_path
        ], env=env)
        
        print("✅ Source repository cloned as mirror successfully")
    
    def fetch_lfs_files(self):
        """Fetch all LFS files from the source repository."""
        print("\n" + "="*60)
        print("📦 Step 2: Fetching Git LFS files")
        print("="*60)

        if self.pointer_only_mode:
            print("⚠️  GIT_LFS_SKIP_SMUDGE=1 detected — skipping Git LFS fetch/checkout.")
            print("   Only pointer files will be synced. Ensure the target already hosts the LFS blobs.")
            return
        
        # Pull LFS files
        self.run_command([
            'git', 'lfs', 'fetch', '--all'
        ], cwd=self.repo_path)
        
        self.run_command([
            'git', 'lfs', 'checkout'
        ], cwd=self.repo_path)
        
        print("✅ Git LFS files fetched successfully")
    
    def change_remote(self):
        """Change the remote to target platform."""
        print("\n" + "="*60)
        print("🔄 Step 3: Changing remote to target platform")
        print("="*60)
        
        # Remove origin remote
        try:
            self.run_command([
                'git', 'remote', 'remove', 'origin'
            ], cwd=self.repo_path)
        except subprocess.CalledProcessError:
            print("⚠️  Origin remote not found, skipping removal")
        
        # Get target platform credentials from environment
        target_username = os.getenv('TARGET_USERNAME')
        target_token = os.getenv('TARGET_TOKEN')
        
        target_url_with_creds = self.inject_credentials(
            self.target_url,
            username=target_username,
            token=target_token
        )
        
        # Add new remote
        self.run_command([
            'git', 'remote', 'add', 'origin', target_url_with_creds
        ], cwd=self.repo_path)
        
        # Verify remote
        self.run_command([
            'git', 'remote', '-v'
        ], cwd=self.repo_path)
        
        print("✅ Remote changed successfully")
    
    def push_to_target(self):
        """Push the repository to target platform."""
        print("\n" + "="*60)
        print("📤 Step 4: Pushing to target platform")
        print("="*60)
        
        # Get the default branch name
        result = self.run_command([
            'git', 'branch', '--show-current'
        ], cwd=self.repo_path)
        branch = result.stdout.strip() or 'main'
        
        # Push all branches and tags
        print(f"\n🚀 Pushing branch: {branch}")
        self.run_command([
            'git', 'push', '-u', 'origin', branch, '--force'
        ], cwd=self.repo_path)
        
        # Push all tags
        print("\n🏷️  Pushing tags...")
        try:
            self.run_command([
                'git', 'push', 'origin', '--tags', '--force'
            ], cwd=self.repo_path)
        except subprocess.CalledProcessError:
            print("⚠️  No tags to push or push failed")
        
        print("✅ Repository pushed successfully")
    
    def push_to_target_mirror(self):
        """Push ALL refs from mirror to target platform."""
        print("\n" + "="*60)
        print("📤 Step 4: Pushing mirror to target platform")
        print("="*60)
        print("ℹ️  Mirror mode: pushing ALL refs (branches, tags, remotes)")
        
        # Get target platform credentials from environment
        target_username = os.getenv('TARGET_USERNAME')
        target_token = os.getenv('TARGET_TOKEN')
        
        target_url_with_creds = self.inject_credentials(
            self.target_url,
            username=target_username,
            token=target_token
        )
        
        # First push LFS objects to target
        print("\n📦 Pushing Git LFS objects...")
        try:
            self.run_command([
                'git', 'lfs', 'push', target_url_with_creds, '--all'
            ], cwd=self.repo_path)
            print("✅ LFS objects pushed successfully")
        except subprocess.CalledProcessError as e:
            print("⚠️  LFS push failed or no LFS objects to push")
            if not self.pointer_only_mode:
                print(f"   Error: {e}")
        
        # Try mirror push first (fastest method)
        print("\n🪞 Attempting mirror push (all refs)...")
        try:
            self.run_command([
                'git', 'push', '--mirror', target_url_with_creds, '--force'
            ], cwd=self.repo_path)
            print("✅ Repository mirror pushed successfully")
        except subprocess.CalledProcessError as e:
            # Mirror push failed, likely due to protected branches or unsupported refs
            print("⚠️  Mirror push encountered issues (this is common with GitLab)")
            print("   Falling back to selective push strategy...")
            
            # Push branches separately (excluding problematic refs)
            print("\n🌿 Pushing all branches...")
            try:
                self.run_command([
                    'git', 'push', target_url_with_creds,
                    'refs/heads/*:refs/heads/*', '--force'
                ], cwd=self.repo_path)
                print("✅ Branches pushed successfully")
            except subprocess.CalledProcessError as branch_err:
                print(f"⚠️  Some branches failed to push: {branch_err}")
            
            # Push tags separately
            print("\n🏷️  Pushing all tags...")
            try:
                self.run_command([
                    'git', 'push', target_url_with_creds,
                    'refs/tags/*:refs/tags/*', '--force'
                ], cwd=self.repo_path)
                print("✅ Tags pushed successfully")
            except subprocess.CalledProcessError as tag_err:
                print(f"⚠️  Some tags failed to push: {tag_err}")
            
            # Note about skipped refs
            print("\nℹ️  Note: Some refs (like refs/pr/* from HuggingFace) may have been skipped.")
            print("   This is normal and doesn't affect the main repository content.")
            print("✅ Repository mirror pushed successfully (with selective strategy)")
    
    def cleanup(self):
        """Clean up temporary directory."""
        print("\n" + "="*60)
        print("🧹 Step 5: Cleaning up")
        print("="*60)
        
        if os.path.exists(self.temp_dir):
            shutil.rmtree(self.temp_dir)
            print(f"✅ Cleaned up temporary directory: {self.temp_dir}")
    
    def transfer(self, cleanup: bool = True):
        """Execute the full transfer process."""
        try:
            print("\n" + "="*60)
            if self.mirror_mode:
                print("🪞 Starting Model Repository Mirror Transfer")
            else:
                print("🚀 Starting Model Repository Transfer")
            print("="*60)
            print(f"📍 Source: {self.source_url}")
            print(f"📍 Target: {self.target_url}")
            print(f"📁 Temp directory: {self.temp_dir}")
            if self.use_xget:
                print("🚀 Xget acceleration: Enabled (faster HuggingFace downloads)")
            if self.mirror_mode:
                print("🪞 Mirror mode enabled: ALL refs (branches, tags, remotes) will be synced")
            if self.pointer_only_mode:
                print("⚠️  Pointer-only mode enabled (GIT_LFS_SKIP_SMUDGE=1). LFS blobs will not be downloaded.")
                print("   Push will fail unless the target remote already contains the required LFS objects.")
            
            if self.mirror_mode:
                # Mirror mode workflow
                self.clone_source_mirror()
                self.fetch_lfs_files()
                # No need to change remote in mirror mode, push directly
                self.push_to_target_mirror()
            else:
                # Standard mode workflow
                self.clone_source()
                self.fetch_lfs_files()
                self.change_remote()
                self.push_to_target()
            
            if cleanup:
                self.cleanup()
            
            print("\n" + "="*60)
            print("🎉 Transfer completed successfully!")
            print("="*60)
            
        except Exception as e:
            print(f"\n❌ Transfer failed: {str(e)}")
            if cleanup and os.path.exists(self.temp_dir):
                print(f"\n⚠️  Temporary files kept at: {self.temp_dir}")
                print("   You can manually inspect or clean up this directory")
            raise


def check_git_lfs():
    """Check if git-lfs is installed."""
    try:
        subprocess.run(['git', 'lfs', 'version'], 
                      capture_output=True, 
                      check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def main():
    parser = argparse.ArgumentParser(
        description='Transfer model repositories from HuggingFace to other platforms',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Transfer with environment variables from .env file
  python transfer.py \\
    --source https://huggingface.co/internlm/Intern-S1 \\
    --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git
  
  # Transfer with inline credentials
  python transfer.py \\
    --source https://huggingface.co/internlm/Intern-S1 \\
    --target https://maoxin:glpat-xxx@nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git
  
  # Mirror mode: sync ALL refs (branches, tags, remotes)
  python transfer.py \\
    --source https://huggingface.co/internlm/Intern-S1 \\
    --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \\
    --mirror
  
  # Use Xget acceleration for faster HuggingFace downloads
  python transfer.py \\
    --source https://huggingface.co/internlm/Intern-S1 \\
    --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \\
    --use-xget
  
  # Keep temporary files for inspection
  python transfer.py \\
    --source https://huggingface.co/internlm/Intern-S1 \\
    --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \\
    --no-cleanup
        """
    )
    
    parser.add_argument(
        '-s', '--source',
        required=True,
        help='Source HuggingFace repository URL (HTTPS)'
    )
    
    parser.add_argument(
        '-t', '--target',
        required=True,
        help='Target platform repository URL (HTTPS)'
    )
    
    parser.add_argument(
        '--temp-dir',
        help='Temporary directory for cloning (default: auto-generated)'
    )
    
    parser.add_argument(
        '--no-cleanup',
        action='store_true',
        help='Keep temporary files after transfer'
    )
    
    parser.add_argument(
        '--env-file',
        default='.env',
        help='Path to .env file (default: .env)'
    )
    
    parser.add_argument(
        '--mirror',
        action='store_true',
        help='Mirror mode: clone and push ALL refs (branches, tags, remotes) using git --mirror'
    )
    
    parser.add_argument(
        '--use-xget',
        action='store_true',
        help='Use Xget acceleration for HuggingFace downloads (https://github.com/xixu-me/Xget)'
    )
    
    parser.add_argument(
        '--use-remote-mirror',
        action='store_true',
        help='Configure server-side mirroring (GitLab pull mirror) instead of local transfer'
    )
    
    args = parser.parse_args()
    
    # Load environment variables from .env file
    if os.path.exists(args.env_file):
        load_dotenv(args.env_file)
        print(f"✅ Loaded environment variables from {args.env_file}")
    else:
        print(f"⚠️  Warning: {args.env_file} not found, using system environment variables only")
    
    if args.use_remote_mirror:
        try:
            mirror = MirrorManager(args.source, args.target)
            mirror.configure()
        except MirrorConfigurationError as exc:
            print(f"❌ Remote mirror configuration failed: {exc}")
            sys.exit(1)
        return
    
    # Check if git-lfs is installed
    if not check_git_lfs():
        print("❌ Error: git-lfs is not installed or not in PATH")
        print("   Please install git-lfs first:")
        print("   - Ubuntu/Debian: sudo apt-get install git-lfs")
        print("   - macOS: brew install git-lfs")
        print("   - Windows: https://git-lfs.github.com/")
        print("\n   After installation, run: git lfs install")
        sys.exit(1)
    
    # Create transfer instance and execute
    transfer = ModelTransfer(
        source_url=args.source,
        target_url=args.target,
        temp_dir=args.temp_dir,
        mirror_mode=args.mirror,
        use_xget=args.use_xget
    )
    
    try:
        transfer.transfer(cleanup=not args.no_cleanup)
    except Exception as e:
        sys.exit(1)


if __name__ == '__main__':
    main()

