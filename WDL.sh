#!/bin/bash

############################## workflow description language ##############################
# workflow, task, call, command and output
# runtime、parameter_meta、meta...
# String, Float, Int, Boolean, File, Array, Map, Object

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
# task
task_A {
	command {...}
	output {...}
}
task_B {
	[ input definitions ]
	command {
		java -jar myExecutable.jar \
			INPUT=${input_file} \
			OUTPUT=${output_basename}.txt
	}
	output {
		File out="${output_basename}.txt"
	}
}

# parameters in workflow & task
workflow myWorkflowName {
	File my_ref
	File my_input
	String name
	call task_A {
		input:
		ref=my_ref,
		in=my_input,
		id=name
	}
	call task_B {
		ref=my_ref,
		in=task_A.out
	}
}
task task_A {
	File ref
	File in
	String id
	command {
		do_stuff R=${ref} I=${in} o=${id}.ext
	}
	output {
		File out="${id}.ext"
	}
}

########## pipeline classification ##########
# LinearChain
workflow LinearChain {
  File firstInput
  call stepA { input: in=firstInput }
  call stepB { input: in=stepA.out }
  call stepC { input: in=stepB.out }
}
task stepA {
  File in
  command { programA I=${in} O=outputA.ext }
  output { File out = "outputA.ext" }
}
task stepB {
  File in
  command { programB I=${in} O=outputB.ext }
  output { File out = "outputB.ext" }
}
task stepC {
  File in
  command { programC I=${in} O=outputC.ext }
  output { File out = "outputC.ext" }
}

# MultiOutMultiIn
workflow MultiOutMultiIn {
  File firstInput
  call stepA { input: in=firstInput }
  call stepB { input: in=stepA.out }
  call stepC { input: in1=stepB.out1, in2=stepB.out2 }
}
task stepA {
  File in
  command { programA I=${in} O=outputA.ext }
  output { File out = "outputA.ext" }
}
task stepB {
  File in
  command { programB I=${in} O1=outputB1.ext O2=outputB2.ext }
  output {
    File out1 = "outputB1.ext"
    File out2 = "outputB2.ext" }
}
task stepC {
  File in1
  File in2
  command { programB I1=${in1} I2=${in2} O=outputC.ext }
  output { File out = "outputC.ext" }
}

# BranchAndMerge
workflow BranchAndMerge {
  File firstInput
  call stepA { input: in=firstInput }
  call stepB { input: in=stepA.out }
  call stepC { input: in=stepA.out }
  call stepD { input: in1=stepC.out, in2=stepB.out }
}
task stepA {
  File in
  command { programA I=${in} O=outputA.ext }
  output { File out = "outputA.ext" }
}
task stepB {
  File in
  command { programB I=${in} O=outputB.ext }
  output { File out = "outputB.ext" }
}
task stepC {
  File in
  command { programC I=${in} O=outputC.ext }
  output { File out = "outputC.ext" }
}
task stepD {
  File in1
  File in2
  command { programD I1=${in1} I2=${in2} O=outputD.ext }
  output { File out = "outputD.ext" }
}

# ScatterGather
workflow ScatterGather {
  Array[File] inputFiles
  scatter (oneFile in inputFiles) {
    call stepA { input: in=oneFile }
  }
  call stepB { input: files=stepA.out }
}
task stepA {
  File in
  command { programA I=${in} O=outputA.ext }
  output { File out = "outputA.ext" }
}
task stepB {
  Array[File] files
  command { programB I=${files} O=outputB.ext }
  output { File out = "outputB.ext" }
}

# taskAlias
workflow taskAlias {
  File firstInput
  File secondInput
  call stepA as firstSample { input: in=firstInput }
  call stepA as secondSample { input: in=secondInput }
  call stepB { input: in=firstSample.out }
  call stepC { input: in=secondSample.out }
}
task stepA {
  File in
  command { programA I=${in} O=outputA.ext }
  output { File out = "outputA.ext" }
}
task stepB {
  File in
  command { programB I=${in} O=outputB.ext }
  output { File out = "outputB.ext" }
}
task stepC {
  File in
  command { programC I=${in} O=outputC.ext }
  output { File out = "outputC.ext" }
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

# complex example
workflow testwdl {
     Int? thread = 6
     String varwdl
     String prefix
     Array[Int] intarray = {1,2,3,4,5}
     if(thread>5) { 
        call taska {
            input:
            vara = varwdl,
            infile = taskb.outfile,
            prefix = prefix
        } 
     }
     scatter (sample in intarray) { 
          call taskb {
               input:
                    varb = 'testb',
                    thread = thread,
                    prefix = sample
          }
     }
}

task taska {
    String vara
    Array[File] infile
    String prefix
    command {
           cat ${sep=" " infile} >${prefix}_${vara}.txt
    }
}
task taskb {
    String varb
    Int thread
    String prefix
    command {
           echo ${varb} ${thread} >${prefix}.txt
    }
    output {
         File outfile = '${prefix}.txt'
    }
}

# simple example 1
workflow helloworld {
	call hello {}
}

task hello {
	String name="brother"
	command {
		echo "hello world" ${name}
	}
}

# simple example 2
workflow myWorkflow {
    call myTask
}
task myTask {
    command {
        echo "hello world"
    }
    output {
        String out = read_string(stdout())
    }
}

# run WDL
java -jar womtool-51.jar validate test.wdl
java -jar ~/software/cromwell-51/womtool-51.jar inputs test.wdl > test.json
java -jar cromwell-51.jar run test.wdl --inputs test.json

# configuration
include required(classpath("application"))

backend {
  default = SGE
  # sge config
  providers {
    SGE {
      actor-factory = "cromwell.backend.impl.sfs.config.ConfigBackendLifecycleActorFactory"
      config {
        # Limits the number of concurrent jobs
        concurrent-job-limit = 50
        # Warning: If set, Cromwell will run 'check-alive' for every job at this interval
        # exit-code-timeout-seconds = 120
        runtime-attributes = """
        Int cpu = 8
        Float? memory_gb
        String? sge_queue
        String? sge_project
        """
        submit = """
        qsub \
        -terse \
        -N ${job_name} \
        -wd ${cwd} \
        -o ${out}.out \
        -e ${err}.err \
        ${"-pe smp " + cpu} \
        ${"-l mem_free=" + memory_gb + "g"} \
        ${"-q " + sge_queue} \
        ${"-P " + sge_project} \
        ${script}
        """
        kill = "qdel ${job_id}"
        check-alive = "qstat -j ${job_id}"
        job-id-regex = "(\\d+)"
        # filesystem config
        filesystems {
          local {
            localization: [
               "hard-link","soft-link", "copy"
              ]
            caching {
              duplication-strategy: [
              "hard-link","soft-link",  "copy"
              ]
              # Default: "md5"
              hashing-strategy: "md5"
              # Default: 10485760 (10MB).
              fingerprint-size: 10485760
              # Default: false
              check-sibling-md5: false
            }
          }
        }
      }
    }
  }
}

java -Dconfig.file=backend.conf -jar cromwell-51.jar run test.wdl --inputs test.json
