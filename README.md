# GPU Support for DC/OS on CoreOS

This project aims to provide GPU support for [DC/OS](https://dcos.io) clusters running with [CoreOS](https://coreos.com/).

Of the operating systems supported by DC/OS the official [nvidia installer](https://www.nvidia.de/Download/index.aspx) only supports RedHat/CentOS. But many people use CoreOS in their DC/OS clusters to have a lighter and smaller OS and still want to use GPUs. For this use case we devised a way to get GPU support running on CoreOS in DC/OS.

## Getting started

1. Locally checkout this repository
2. Compile nvidia drivers for your CoreOS version (Can be run on any linux machine with docker installed, needs neither CoreOS nor an Nvidia GPU)
   1. Edit `common.sh` and set your CoreOS and Nvidia driver versions
   2. Run `build_driver.sh`
3. Upload the resulting `nvidia.tar.gz` to a place from where your cluster nodes can download it (e.g. an S3 bucket).
4. Extend your cluster provisioning (e.g. terraform, ansible) to
   1. Download and extract the `nvidia.tar.gz`
   2. Run `install_nvidia.sh` (with sudo)
   3. Optional: To make sure the drivers also get loaded after a restart add the `nvidia.service` file to your systemctl units and enable it. You need to do this after DC/OS has been installed as the unit contains a `Before` directive to start before the `dcos-mesos-slave`.

You do not need a special CoreOS image, instead you can continue to use your normal image (for AWS this will probably be the official AMIs provided by CoreOS).

Example snippet for cluster provisioning with terraform:

```terraform
  provisioner "remote-exec" {
    inline = [
      "wget -O /tmp/nvidia.tar.gz https://s3.eu-central-1.amazonaws.com/my-bucket/nvidia.tar.gz",
      "sudo tar xfz /tmp/nvidia.tar.gz -C /tmp",
      "cd /tmp && sudo chmod +x /tmp/install_nvidia.sh && sudo /tmp/install_nvidia.sh",
      "sudo /opt/nvidia/startup.sh"
    ]
  }

  provisioner "remote-exec" {
    inline = [
        # ... install DC/OS
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/nvidia.service /etc/systemd/system/nvidia.service",
      "sudo systemctl enable /etc/systemd/system/nvidia.service"
    ]
  }
```

This has only been tested with CoreOS 1855.4.0 running on Amazon EC2 GPU instances.

After you have completed the setup refer to the [DC/OS documentation](https://docs.mesosphere.com/1.13/deploying-services/gpu/#using-gpus-in-your-apps) on how to run GPU-enabled apps in your cluster.

If you find a bug or have a feature request please open an issue in Github.

## Behind the curtain

The first challenge is that nvidia has no official support for CoreOS. So to make this work we need to trick the nvidia installer into compiling the drivers anyway.
To do this we create a CoreOS docker container and prepare the kernel sources corresponding to the CoreOS version. Then we download and run the nvidia installer and tell it to use the CoreOS kernel sources. Installation of the compiled modules will fail as we are inside a docker container and the running kernel of the host system is most likely not the same as the CoreOS kernel. But we can ignore that failure as we only need the module files.

The second challenge is to get the driver installed. To make it easy to integrate we do not use a custom-built OS image, instead the build process assembles an archive file that just needs to be made available to the running CoreOS instances (.e.g. via http download) and contains everything needed to install the driver.

## Disclaimer

This project is in no way affiliated with CoreOS or Nvidia. This project is not officially supported by Mesosphere. Use it at your own risk.

## Acknowledgements

* Driver build is running using https://github.com/BugRoger/coreos-developer-docker
* Heavily inspired by https://github.com/src-d/coreos-nvidia and https://github.com/Clarifai/coreos-nvidia
