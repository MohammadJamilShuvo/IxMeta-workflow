KDB=config["classification"]["kraken_db"]

rule kraken2:
    input:
        r1=f"{OUT}/02_host_depletion/nonhost/{{sample}}_R1.fastq.gz",
        r2=f"{OUT}/02_host_depletion/nonhost/{{sample}}_R2.fastq.gz"
    output:
        report=f"{OUT}/03_classification/{{sample}}.kraken.report",
        classified=f"{OUT}/03_classification/{{sample}}.kraken.out"
    threads: config["threads"]["kraken2"]
    conda: "../envs/classification.yaml"
    params:
        conf=config["classification"]["confidence"],
        mhg=config["classification"]["minimum_hit_groups"]
    shell:
        """mkdir -p {OUT}/03_classification; kraken2 --db {KDB} --paired {input.r1} {input.r2} \
        --threads {threads} --confidence {params.conf} --minimum-hit-groups {params.mhg} \
        --report {output.report} --output {output.classified}"""

rule bracken:
    input: f"{OUT}/03_classification/{{sample}}.kraken.report"
    output: f"{OUT}/03_classification/{{sample}}.bracken.tsv"
    conda: "../envs/classification.yaml"
    params:
        level=config["classification"]["bracken_level"],
        readlen=config["classification"]["read_length"],
        threshold=config["classification"]["threshold"]
    shell:
        "bracken -d {KDB} -i {input} -o {output} -r {params.readlen} -l {params.level} -t {params.threshold}"

rule bracken_matrix:
    input: expand(f"{OUT}/03_classification/{{sample}}.bracken.tsv", sample=SAMPLES)
    output:
        counts=f"{OUT}/07_community/bracken_counts.tsv",
        relative=f"{OUT}/07_community/bracken_relative.tsv",
        prevalence=f"{OUT}/07_community/taxon_prevalence.tsv"
    conda: "../envs/report.yaml"
    shell:
        "python scripts/build_bracken_matrix.py --inputs {input} --counts {output.counts} --relative {output.relative} --prevalence {output.prevalence}"

rule community_analysis:
    input: f"{OUT}/07_community/bracken_relative.tsv"
    output:
        shannon=f"{OUT}/07_community/shannon.tsv",
        bray=f"{OUT}/07_community/bray_curtis.tsv"
    conda: "../envs/report.yaml"
    shell:
        "Rscript scripts/community_analysis.R {input} {OUT}/07_community"
