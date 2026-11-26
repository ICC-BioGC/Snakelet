rule test_basespace:
    output: "dummy_bs.txt"
    conda: "workflow/envs/basespace_env.yaml"
    shell: "bs --version && touch {output}"
