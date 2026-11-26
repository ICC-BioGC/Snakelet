# workflow/rules/fastp.smk
# Quality control and trimming of raw reads using fastp.
# This rule uses the official Snakemake wrapper for fastp.

rule fastp_pe:
    input:
        # Input function defined in common.smk to get R1 and R2 for a sample
        get_fastq
    output:
        # Trimmed reads (paired-end)
        r1=f"{OUTDIR}/02_fastp/{{sample}}_R1.fastq.gz",
        r2=f"{OUTDIR}/02_fastp/{{sample}}_R2.fastq.gz",
        # QC reports
        html=f"{OUTDIR}/02_fastp/{{sample}}.html",
        json=f"{OUTDIR}/02_fastp/{{sample}}.json"
    conda:
        # Environment file created earlier
        "../envs/fastp_env.yaml"
    log:
        f"logs/fastp/{{sample}}.log"
    threads: 4
    params:
        # Additional parameters can be passed here if needed.
        # For example: extra="--detect_adapter_for_pe"
        extra=""
    wrapper:
        # Pinned version of the official fastp wrapper
        "v3.13.2/bio/fastp"
