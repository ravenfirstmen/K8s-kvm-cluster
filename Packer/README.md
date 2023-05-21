# About

Packer manifests to create images (QEMU/LibVirt) for providing a local kubernetes nodes

# Build the images (Ubuntu 22.04 based)

Install packer (https://developer.hashicorp.com/packer/downloads)

review the `source` section of the manifests and change to the correct base image

```
source "libvirt" "..." {
  volume {
    source {    
    ...
      urls = [...]        
```

after


```
packer init . && packer build .
```
