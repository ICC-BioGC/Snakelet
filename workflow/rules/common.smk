# =============================================================================
# workflow/rules/common.smk
# Helper functions shared across rule modules.
#
# Keeping these separate from rules improves readability and avoids
# duplicating logic.
# =============================================================================

def get_fastq(wildcards):
    """
    Return the list of FASTQ files (R1, R2) for a given sample.

    This is an input function, evaluated during the DAG phase, so it can
    safely access the sample sheet and wildcard values.

    Args:
        wildcards: Snakemake wildcards object (has .sample attribute).

    Returns:
        List of two file paths [R1, R2].
    """
    row = samples_df[samples_df["sample"] == wildcards.sample].iloc[0]
    return [row["fastq_r1"], row["fastq_r2"]]


def get_contigs(wildcards):
    """
    Return the path to the assembled contigs file for a given sample.

    Useful for rules that take contigs as input (e.g., Prokka, MLST, RGI).
    """
    return f"{OUTDIR}/03_spades/{wildcards.sample}/contigs.fasta"


def get_prokka_gff(wildcards):
    """
    Return the path to the Prokka GFF file for a given sample.
    """
    return f"{OUTDIR}/06_prokka/{wildcards.sample}/{wildcards.sample}.gff"


def get_kraken2_report(wildcards):
    """
    Return the path to the Kraken2 report for a given sample.
    """
    return f"{OUTDIR}/09_kraken2/{wildcards.sample}.kraken.report"


def get_threads(default=1):
    """
    Return the number of threads for a rule, capped by the global maximum.

    Reads the 'max_threads' value from the config if present, otherwise
    returns the provided default.
    """
    return min(default, config.get("max_threads", default))
