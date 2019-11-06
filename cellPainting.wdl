# Workflow for cellprofiler cell painting pipeline on GCP.
#
# Notes:
#
# Alpha 
#
# 
#
#
#############

workflow cellPainting {

  ##################################
  #### Required basic arguments ####
  ##################################
  String plate_id
  String bucket_images_path
  ##############################################
  #### Required basic pe2LoadData arguments ####
  ##############################################
  File pe2_config
  File pe2_illum_cppipe
  
  #Runtime attributes
  String pe2_docker
  Int pe2_docker_memory
  Int pe2_docker_hhd
  Int? pe2_preemptible_attempts
  Int? pe2_docker_cpu

  ###############################################
  #### Required basic CellProfiler arguments ####
  ###############################################
  File cellprofiler_analysis_cppipe

  #Runtime attributes
  String cellprofiler_docker
  Int cellprofiler_docker_memory
  Int cellprofiler_docker_hhd
  Int? cellprofiler_preemptible_attempts
  Int? cellprofiler_docker_cpu

  ############################################
  #### Required basic cytominer arguments ####
  ############################################
  File cytominer_config

  #Runtime attributes
  String cytominer_docker
  Int cytominer_docker_memory
  Int cytominer_docker_hhd
  Int? cytominer_preemptible_attempts
  Int? cytominer_docker_cpu

  ##################################
  ####  Required GCP Auth stuff ####
  ##################################
  File exc_svc_key
  String ext_gcp_project
}

task pe2loaddata {

  File pe2_config
  File pe2_illum_cppipe
  File exc_svc_key
  String plate_id
  String ext_gcp_project
  String bucket_images_path

  String pe2_docker
  Int pe2_docker_hhd
  Int pe2_docker_memory
  Int? pe2_preemptible_attempts
  Int? pe2_docker_cpu

  command {

    echo "****************************************"
    echo "INFO-->Gsutil config and setup "
    echo "****************************************"

    cat << EOF > /root/.boto
    [Credentials]
    gs_service_key_file = ${exc_svc_key}
    [Boto]
    https_validate_certificates = True
    [GSUtil]
    default_project_id = ${ext_gcp_project}
    EOF

    echo "****************************************"
    echo "INFO-->Localising specific images "
    echo "****************************************"

    gsutil -m cp ${bucket_images_path}* /usr/local/src/workspace/images/
    echo "INFO-->Image Count "
    ls /usr/local/src/workspace/images/ | grep -c tiff

    echo "****************************************"
    echo "INFO-->Runnig pe2loaddata load_data.csv."
    echo "****************************************"
    #TODO: Check the configuration file before moving on.
    #TODO: Hardcode file directory so it's not so dam long.
    python /usr/local/src/workspace/software/pe2loaddata/pe2loaddata.py \
    --index-directory /usr/local/src/workspace/images/ \
    ${pe2_config} \
    /usr/local/src/workspace/load_data_csv/load_data.csv

    echo "****************************************"
    echo "INFO-->Runnig illum_cppipe ~ generating npy files"
    echo "****************************************"

    cellprofiler -p ${pe2_illum_cppipe} -c -r -i /usr/local/src/workspace/images/ \
      --data-file /usr/local/src/workspace/load_data_csv/load_data.csv -o /usr/local/src/workspace/analysis/

    echo "****************************************"
    echo "INFO-->Appending npy files to load_data csv"
    echo "****************************************"

    python /usr/local/src/workspace/software/pe2loaddata/append_illum_cols.py \
     --plate-id ${plate_id} \
     --illum-directory /usr/local/src/workspace/analysis/ \
     --illum_filetype .npy \
     ${pe2_config} \
     /usr/local/src/workspace/load_data_csv/load_data.csv \
     /usr/local/src/workspace/load_data_csv/illum_load_data.csv

    echo "****************************************"
    echo "INFO-->Creaing scatter csv files"
    echo "****************************************"

    python /usr/local/src/workspace/software/task_bundler.py --input_csv /usr/local/src/workspace/load_data_csv/illum_load_data.csv \
    --output_dir /usr/local/src/workspace/batchfiles/

    echo "****************************************"
    echo "INFO-->Globbing Cleanup"
    echo "****************************************"
    cp /usr/local/src/workspace/analysis/*.npy .
    cp /usr/local/src/workspace/load_data_csv/illum_load_data.csv .
    cp /usr/local/src/workspace/batchfiles/illum_load_data_*.csv .
  }

  runtime {
    docker: pe2_docker
    memory: pe2_docker_memory + " MB"
    disks: "local-disk " + pe2_docker_hhd + " HDD"
    preemptible: select_first([pe2_preemptible_attempts, 5])
    cpu: select_first([pe2_docker_cpu, 2])
  }

  output {
    Array[File] npy_files = glob("*.npy")
    Array[File] batch_csv_files = glob("illum_load_data_*.csv") 
  }

}

task analysisPipeline {

  File illum_csv 
  Array[File] npy_files
  File cellprofiler_analysis_cppipe
  String bucket_images_path
  File exc_svc_key
  String ext_gcp_project
  String regex = "'r[0-9]{1,3}c[0-9]{1,3}f[0-9]{1,3}p[0-9]{1,3}-ch[0-9]{1,3}sk[0-9]{1,3}fk[0-9]{1,3}fl[0-9]{1,3}.tiff'"

  String cellprofiler_docker
  Int cellprofiler_docker_hhd
  Int cellprofiler_docker_memory
  Int? cellprofiler_preemptible_attempts
  Int? cellprofiler_docker_cpu

  command {

    echo "****************************************"
    echo "INFO-->Moving terra localised files "
    echo "****************************************"
    find . -type f -name "*.npy" | xargs mv -t /usr/local/src/workspace/analysis/
    find . -type f -name "illum_load_data_*.csv" | xargs mv -t /usr/local/src/workspace/load_data_csv/

    echo "****************************************"
    echo "INFO-->Gsutil config and setup "
    echo "****************************************"
    cat << EOF > /root/.boto
    [Credentials]
    gs_service_key_file = ${exc_svc_key}
    [Boto]
    https_validate_certificates = True
    [GSUtil]
    default_project_id = ${ext_gcp_project}
    EOF

    cat /usr/local/src/workspace/load_data_csv/illum_load_data_*.csv |grep -oP ${regex} | sed 's+^+${bucket_images_path}+' > download_list.txt
    echo "INFO-->Image Download Manafest "
    cat download_list.txt
    echo "INFO-->END Manafest"

    echo "****************************************"
    echo "INFO-->Localising images to docker"
    echo "****************************************"
    cat download_list.txt | gsutil -m cp -I /usr/local/src/workspace/images/

    echo "****************************************"
    echo "INFO-->Runnig Cellprofiler pipline"
    echo "****************************************"
      cellprofiler -p ${cellprofiler_analysis_cppipe} -c -r -i /usr/local/src/workspace/images/ \
       --data-file /usr/local/src/workspace/load_data_csv/illum_load_data*.csv -o .
  }

  runtime {
    docker: cellprofiler_docker
    memory: cellprofiler_docker_memory + " MB"
    disks: "local-disk " + cellprofiler_docker_hhd + " HDD"
    preemptible: select_first([cellprofiler_preemptible_attempts, 5])
    cpu: select_first([cellprofiler_docker_cpu, 2])
  }

  output {
    Array[File] out_csvs = glob("*.csv")
  }
}

task injestCSV {

  Array[Array[File]] out_csvs
  Array[File] flat_out_csvs = flatten(out_csvs)
  File cytominer_config

  String cytominer_docker
  Int cytominer_docker_hhd
  Int cytominer_docker_memory
  Int? cytominer_preemptible_attempts
  Int? cytominer_docker_cpu

  command {
    echo "****************************************"
    echo "INFO-->Combinding CSVs."
    echo "****************************************"
    export SHARD_DIR=$(find . -type d -name "call-analysisPipeline")
    python3 /usr/local/src/workspace/software/task_bundler.py --start_dir . --dir_level 2

    echo "****************************************"
    echo "INFO-->Running cytominer"
    echo "****************************************"
    cytominer-database ingest $SHARD_DIR sqlite:///backend.sqlite -c ${cytominer_config}
  }

  runtime {
    docker: cytominer_docker
    memory: cytominer_docker_memory + " MB"
    disks: "local-disk " + cytominer_docker_hhd + " HDD"
    preemptible: select_first([cytominer_preemptible_attempts, 5])
    cpu: select_first([cytominer_docker_cpu, 2])
  }

  output {
    Array[File] database_out = glob("backend.*")
  }
}

