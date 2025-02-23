FROM archlinux:base

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm nasm lld qemu-full edk2-ovmf

WORKDIR /minimos

CMD ["/bin/bash"]
