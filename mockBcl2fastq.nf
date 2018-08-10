#!/usr/bin/env nextflow

import java.io.File
import groovy.util.*
import org.yaml.snakeyaml.Yaml

process bcl2fastq {
  tag { myNum }
  input: 
  val myNum from (['one','two','three','one', 'two', 'one', 'two', 'four', 'four', 'three', 'one', 'four', 'two', 'three', 'three', 'four'])

  output: 
  //file("*.bam") into alignment
  set val(myNum), file("*.bam")  into alignment

 
  script: 
  """
  echo ${myNum} > L1_${myNum}.1.bam 
  echo ${myNum} > L2_${myNum}.1.bam 
  echo ${myNum} > L3_${myNum}.1.bam 
  echo ${myNum} > L4_${myNum}.1.bam 
  echo ${myNum} > L1_${myNum}.2.bam 
  echo ${myNum} > L2_${myNum}.2.bam 
  echo ${myNum} > L3_${myNum}.2.bam 
  echo ${myNum} > L4_${myNum}.2.bam 
  """
}

alignment
	.groupTuple()
	.map { it ->
		[it[0], it[1].flatten()]
	}
	.into { bamChan; bamChan2 }

//process combineFastq{
//
//  tag { myNum } 
//  input: 
//  set val(myNum), val(bams) from bamChan
//  
//  output:
//  set val(myNum), file("*.txt") into result
// 
//  script:
//  """
//  cat ${bams.join(" ")}>${myNum}.txt
//  """
//}


Channel.from(params.analysis)
	.map { it ->
		 library = it.keySet()[0]
		 [library, it.get(library)]
	}
  .set { analysisGroup }

bamChan
      .join(analysisGroup)
      .groupTuple(by: 2)
      .set { analyisGroupFiles }


process submitSecondarAnalysis {
  tag { [ analysisType, libraries ] }
  
  echo true

  input:
  set val(libraries), val(files), val(analysisType) from analyisGroupFiles

  script:
  File tileFastqPaths = new File("RunID_${analysisType}_tile_fastqs_paths.yaml")
  tileFastqPaths << "tileFastqs:\n"
  libraries.eachWithIndex { sample, idx ->
      tileFastqPaths <<"  - ${sample}:\n"
      files[idx].each { tileFastq ->
        tileFastqPaths << "    - ${tileFastq}\n"
      }
  }
  """
  """
}

