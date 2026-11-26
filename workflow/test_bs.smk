rule test_basespace:
    output: "dummy_bs.txt"
    conda: "envs/basespace_env.yaml"
    shell: "bs --version && touch {output}"
## snakemake -s test_bs.smk --conda-create-envs-only --cores 1
## conda run -n basespace_env bs --version
