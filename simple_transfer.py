#!/usr/bin/env python3
"""
Lightweight Git Repository Transfer Tool
Simple script for syncing Git repositories with LFS support.
"""

import os
import sys
import subprocess
import tempfile
import shutil
from urllib.parse import urlparse, urlunparse


def inject_credentials(url, username=None, token=None):
    """Inject credentials into Git URL."""
    if not token:
        return url
    
    parsed = urlparse(url)
    
    # Skip if already has credentials
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


def run_git_command(cmd, cwd=None):
    """Execute git command and stream output."""
    print(f"→ {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=cwd, text=True)
    if result.returncode != 0:
        raise subprocess.CalledProcessError(result.returncode, cmd)
    return result


def transfer_repository(source_url, target_url, hf_username=None, hf_token=None, 
                       target_username=None, target_token=None):
    """Transfer a single repository from source to target."""
    print("\n" + "=" * 70)
    print(f"📦 Transferring Repository")
    print("=" * 70)
    print(f"Source: {source_url}")
    print(f"Target: {target_url}")
    
    # Create temporary directory
    temp_dir = tempfile.mkdtemp(prefix="git_sync_")
    repo_path = os.path.join(temp_dir, "repo")
    
    try:
        # Inject credentials
        source_with_creds = inject_credentials(source_url, hf_username, hf_token)
        target_with_creds = inject_credentials(target_url, target_username, target_token)
        
        # Step 1: Clone source repository
        print("\n📥 Step 1/4: Cloning source repository...")
        run_git_command(['git', 'clone', source_with_creds, repo_path])
        
        # Step 2: Fetch all LFS files
        print("\n📦 Step 2/4: Fetching Git LFS files...")
        run_git_command(['git', 'lfs', 'fetch', '--all'], cwd=repo_path)
        run_git_command(['git', 'lfs', 'checkout'], cwd=repo_path)
        
        # Step 3: Change remote to target
        print("\n🔄 Step 3/4: Changing remote to target...")
        run_git_command(['git', 'remote', 'remove', 'origin'], cwd=repo_path)
        run_git_command(['git', 'remote', 'add', 'origin', target_with_creds], cwd=repo_path)
        
        # Step 4: Push to target
        print("\n📤 Step 4/4: Pushing to target repository...")
        
        # Push LFS objects first
        run_git_command(['git', 'lfs', 'push', 'origin', '--all'], cwd=repo_path)
        
        # Get current branch
        result = subprocess.run(
            ['git', 'branch', '--show-current'],
            cwd=repo_path,
            capture_output=True,
            text=True
        )
        branch = result.stdout.strip() or 'main'
        
        # Push branch
        run_git_command(['git', 'push', '-u', 'origin', branch, '--force'], cwd=repo_path)
        
        # Push tags
        try:
            run_git_command(['git', 'push', 'origin', '--tags', '--force'], cwd=repo_path)
        except subprocess.CalledProcessError:
            print("⚠️  No tags to push or tags push failed")
        
        print("\n✅ Transfer completed successfully!")
        return True
        
    except Exception as e:
        print(f"\n❌ Transfer failed: {e}")
        return False
        
    finally:
        # Cleanup
        if os.path.exists(temp_dir):
            shutil.rmtree(temp_dir)


def main():
    """Main entry point."""
    # Read environment variables
    hf_username = os.getenv('HF_USERNAME')
    hf_token = os.getenv('HF_TOKEN')
    target_username = os.getenv('TARGET_USERNAME')
    target_token = os.getenv('TARGET_TOKEN')
    
    # Get repository pairs from command line arguments
    if len(sys.argv) < 3:
        print("Usage: python3 simple_transfer.py <source_url> <target_url> [source2 target2 ...]")
        print("\nExample:")
        print("  python3 simple_transfer.py \\")
        print("    https://huggingface.co/model1 https://target.com/model1.git \\")
        print("    https://huggingface.co/model2 https://target.com/model2.git")
        sys.exit(1)
    
    # Parse repository pairs
    repos = []
    args = sys.argv[1:]
    if len(args) % 2 != 0:
        print("❌ Error: Repository URLs must be in pairs (source target)")
        sys.exit(1)
    
    for i in range(0, len(args), 2):
        repos.append((args[i], args[i + 1]))
    
    print("\n" + "=" * 70)
    print(f"🚀 Git Repository Transfer Tool")
    print("=" * 70)
    print(f"Total repositories to transfer: {len(repos)}")
    
    # Transfer each repository
    success_count = 0
    failed_repos = []
    
    for idx, (source, target) in enumerate(repos, 1):
        print(f"\n{'=' * 70}")
        print(f"Repository {idx}/{len(repos)}")
        print('=' * 70)
        
        success = transfer_repository(
            source, target,
            hf_username, hf_token,
            target_username, target_token
        )
        
        if success:
            success_count += 1
        else:
            failed_repos.append(source)
    
    # Summary
    print("\n" + "=" * 70)
    print("📊 Transfer Summary")
    print("=" * 70)
    print(f"Total: {len(repos)}")
    print(f"✅ Success: {success_count}")
    print(f"❌ Failed: {len(failed_repos)}")
    
    if failed_repos:
        print("\nFailed repositories:")
        for repo in failed_repos:
            print(f"  - {repo}")
        sys.exit(1)
    else:
        print("\n🎉 All transfers completed successfully!")
        sys.exit(0)


if __name__ == '__main__':
    main()

