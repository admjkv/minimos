FROM archlinux:base

RUN pacman -Syu --noconfirm
RUN pacman -S --noconfirm nasm lld qemu-base edk2-ovmf

WORKDIR /minimos

CMD ["/bin/bash"]
