# workflow/rules/fastp.smk
# Quality control and trimming using fastp.
# This is one of two alternatives for the QC step (the other is FastQC).

rule fastp_pe:
    input:
        get_fastq
    output:
        r1=f"{get_step_dir('fastp')}/{{sample}}_R1.fastq.gz",
        r2=f"{get_step_dir('fastp')}/{{sample}}_R2.fastq.gz",
        html=f"{get_step_dir('fastp')}/{{sample}}.html",
        json=f"{get_step_dir('fastp')}/{{sample}}.json"
    conda:
        "../envs/fastp_env.yaml"
    log:
        f"logs/fastp/{{sample}}.log"
    threads: 4
    wrapper:
        "v3.13.2/bio/fastp"
