cd C:\Users\David\Documents\GitHub\OnutOS

arm-none-eabi-gcc -DEMULATOR_MODE -DRPI2 -O2 -mfpu=neon-vfpv4 -mfloat-abi=hard -mcpu=cortex-a7 -mtune=cortex-a7 -nostartfiles -nostdlib -ffreestanding -g ./source/main.S ./source/usb.S ./source/mem.S ./source/gpio.S ./source/time.S ./source/screen.S ./source/mailbox.S ./source/ui.S ./source/bitmap.S ./source/window.S ./source/control.S ./source/object.S -o ./kernel.elf -T kernel.ld

arm-none-eabi-objcopy ./kernel.elf -O binary ./build/kernel7.img
