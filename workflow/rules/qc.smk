def r1(w): return READS[w.sample][0]
def r2(w): return READS[w.sample][1]

rule fastp:
    input:
        r1=r1,
        r2=r2
    output:
        r1=f"{OUT}/01_qc/trimmed/{{sample}}_R1.fastq.gz",
        r2=f"{OUT}/01_qc/trimmed/{{sample}}_R2.fastq.gz",
        html=f"{OUT}/01_qc/fastp/{{sample}}.html",
        json=f"{OUT}/01_qc/fastp/{{sample}}.json"
    threads: config["threads"]["fastp"]
    conda: "../envs/qc.yaml"
    params:
        minlen=config["fastp"]["min_length"],
        q=config["fastp"]["qualified_quality_phred"],
        up=config["fastp"]["unqualified_percent_limit"]
    shell:
        """mkdir -p {OUT}/01_qc/trimmed {OUT}/01_qc/fastp; \
        fastp -i {input.r1} -I {input.r2} -o {output.r1} -O {output.r2} \
        --detect_adapter_for_pe --length_required {params.minlen} \
        --qualified_quality_phred {params.q} --unqualified_percent_limit {params.up} \
        --thread {threads} --html {output.html} --json {output.json}"""

rule fastqc:
    input:
        r1=f"{OUT}/01_qc/trimmed/{{sample}}_R1.fastq.gz",
        r2=f"{OUT}/01_qc/trimmed/{{sample}}_R2.fastq.gz"
    output:
        f"{OUT}/01_qc/fastqc/{{sample}}_R1_fastqc.zip",
        f"{OUT}/01_qc/fastqc/{{sample}}_R2_fastqc.zip"
    threads: config["threads"]["fastqc"]
    conda: "../envs/qc.yaml"
    shell:
        "mkdir -p {OUT}/01_qc/fastqc; fastqc -t {threads} -o {OUT}/01_qc/fastqc {input.r1} {input.r2}"

rule multiqc:
    input:
        expand(f"{OUT}/01_qc/fastp/{{sample}}.json", sample=SAMPLES),
        expand(f"{OUT}/01_qc/fastqc/{{sample}}_R1_fastqc.zip", sample=SAMPLES),
        expand(f"{OUT}/01_qc/fastqc/{{sample}}_R2_fastqc.zip", sample=SAMPLES)
    output:
        f"{OUT}/01_qc/multiqc_report.html"
    conda: "../envs/qc.yaml"
    shell:
        "multiqc -f -o {OUT}/01_qc {OUT}/01_qc"
