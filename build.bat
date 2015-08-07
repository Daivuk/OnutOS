arm-none-eabi-gcc -DRPI2 -O2 -mfpu=neon-vfpv4 -mfloat-abi=hard -mcpu=cortex-a7 -march=armv7-a -mtune=cortex-a7 -nostartfiles -nostdlib -ffreestanding -g ./source/main.S ./source/usb.S ./source/mem.S ./source/gpio.S ./source/time.S ./source/screen.S ./source/mailbox.S -o ./kernel.elf -T kernel.ld

arm-none-eabi-objcopy ./kernel.elf -O binary ./build/kernel7.img
