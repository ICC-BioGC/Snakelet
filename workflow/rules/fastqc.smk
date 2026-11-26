# workflow/rules/fastqc.smk
# Quality control using FastQC.
# Input depends on the QC mode:
#   - "full": FastQC runs on fastp-trimmed reads
#   - "fastqc": FastQC runs on raw reads (no trimming)

rule fastqc:
    input:
        get_qc_fastq_input
    output:
        html=f"{get_step_dir('fastqc')}/{{sample}}_fastqc.html",
        zip=f"{get_step_dir('fastqc')}/{{sample}}_fastqc.zip"
    conda:
        "../envs/fastqc_env.yaml"
    log:
        f"logs/fastqc/{{sample}}.log"
    threads: 4
    shell:
        """
        fastqc {input} \
            --outdir {get_step_dir('fastqc')} \
            --threads {threads} \
            > {log} 2>&1
        """
