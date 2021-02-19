#!/bin/bash

############################## workflow description language ##############################
# workflow, task, call, command and output
# runtime、parameter_meta、meta...

# workflow
workflow myWorkflowName {
	call task_A
	call task_B
	call task_C as task_alias {
		input:
		task_var1=workflow_var1,
		task_var2=workflow_var2,
		...
	}
}

task_A {
	command {
		...
	}
	output {
		...
	}
}
task_B {
	[ input definitions ]
	command {
		java -jar myExecutable.jar \
			INPUT=${input_file} \
			OUTPUT=${output_basename}.txt
	}
	output {
		File out = "${output_basename}.txt"
	}
}

# example
workflow helloHaplotypeCaller {
	File Ref
	String Sample
	call haplotypeCaller {
		input:
		RefFasta=Ref,
		sampleName=Sample
	}
}

task haplotypeCaller {
	File GATK
	File RefFasta
	File RefIndex
	File RefDict
	String sampleName
	File inputBAM
	File bamIndex
	command {
		java -jar ${GATK} \
			-T HaplotypeCaller \
			-R ${RefFasta} \
			-I ${inputBAM} \
			-o ${sampleName}.raw.indels.snps.vcf
	}
	output {
		File rawVCF = "${sampleName}.raw.indels.snps.vcf"
	}
}

# simple example
workflow helloworld {
	call hello {}
}

task hello {
	String name="brother"
	command {
		echo "hello world" ${name}
	}
}
