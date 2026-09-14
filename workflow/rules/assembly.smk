rule megahit:
    input:
        r1=f"{OUT}/02_host_depletion/nonhost/{{sample}}_R1.fastq.gz",
        r2=f"{OUT}/02_host_depletion/nonhost/{{sample}}_R2.fastq.gz"
    output:
        contigs=f"{OUT}/04_assembly/{{sample}}/final.contigs.fa"
    threads: config["threads"]["assembly"]
    conda: "../envs/assembly.yaml"
    params:
        outdir=lambda w: f"{OUT}/04_assembly/{w.sample}",
        minlen=config["assembly"]["min_contig_len"],
        preset=config["assembly"].get("presets", "meta-sensitive")
    shell:
        """rm -rf {params.outdir}; \
        megahit -1 {input.r1} -2 {input.r2} -o {params.outdir} -t {threads} \
        --min-contig-len {params.minlen} --presets {params.preset}"""
