# =============================================================================
# workflow/rules/common.smk
# System-aware resource detection.
# =============================================================================

import psutil
import multiprocessing
import os

def get_system_resources():
    """
    Detects available system resources and returns a dictionary.
    This runs when the Snakefile is parsed, before any job is scheduled.
    """
    total_mem_gb = psutil.virtual_memory().total / (1024**3)
    total_cores = multiprocessing.cpu_count()
    
    # Check if running on a shared server (heuristic: hostname or env var)
    # You can customize this logic. For example, check for a specific env var
    # that is set on your HPC login node.
    is_shared = os.environ.get("HPC_ENVIRONMENT", "false").lower() == "true"
    
    if is_shared:
        # Conservative settings for shared servers to avoid crashing
        # Use only a fraction of the resources, leaving headroom for others.
        usable_cores = max(1, total_cores // 4)
        usable_mem_gb = max(1, int(total_mem_gb // 2))
    else:
        # For a local workstation, use most of the available resources.
        usable_cores = max(1, total_cores - 1)  # Leave one core for the OS
        usable_mem_gb = max(1, int(total_mem_gb * 0.8))
        
    return {
        "cores": usable_cores,
        "mem_gb": usable_mem_gb,
        "total_cores": total_cores,
        "total_mem_gb": total_mem_gb,
        "is_shared": is_shared
    }

# Detect resources once at startup
SYSTEM_RESOURCES = get_system_resources()

# Now you can use these values as defaults in your rules or config.
# For example, override the config defaults if not explicitly set.
config.setdefault("max_threads", SYSTEM_RESOURCES["cores"])
config.setdefault("max_memory_gb", SYSTEM_RESOURCES["mem_gb"])

# You can also print a summary for the user to see.
print(f"--- System Resource Detection ---")
print(f"Detected {SYSTEM_RESOURCES['total_cores']} CPU cores, "
      f"{SYSTEM_RESOURCES['total_mem_gb']:.1f} GB RAM.")
print(f"Mode: {'Shared Server (Conservative)' if SYSTEM_RESOURCES['is_shared'] else 'Local Workstation'}")
print(f"Using up to {SYSTEM_RESOURCES['cores']} cores and "
      f"{SYSTEM_RESOURCES['mem_gb']} GB RAM for the workflow.")
print(f"---------------------------------")
