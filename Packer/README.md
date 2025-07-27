# About

Packer manifests to create images via QEMU for providing a local kubernetes nodes

# Build the images (Ubuntu 24.04 based)

Install packer (https://developer.hashicorp.com/packer/downloads)

and then

```
packer init . && packer build .
```
