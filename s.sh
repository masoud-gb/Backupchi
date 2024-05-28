#!/bin/bash

# اطلاعات نسخه‌های اوبونتو
declare -a versions=("20.04" "18.04" "16.04")

echo "لطفاً نسخه اوبونتو مورد نظر خود را انتخاب کنید:"

# نمایش لیست نسخه‌ها
for i in "${!versions[@]}"; do
  echo "$i) Ubuntu ${versions[$i]}"
done

# خواندن ورودی کاربر
read -p "شماره نسخه مورد نظر را وارد کنید: " version_index

# بررسی ورودی معتبر
if [[ $version_index -ge 0 && $version_index -lt ${#versions[@]} ]]; then
  selected_version=${versions[$version_index]}
  echo "شما نسخه اوبونتو $selected_version را انتخاب کردید."
else
  echo "شماره نامعتبر است."
  exit 1
fi

# اطمینان از تمایل کاربر
read -p "این عملیات داده‌های سرور را از بین می‌برد. آیا مطمئن هستید که می‌خواهید ادامه دهید؟ (yes/no): " confirmation
if [[ $confirmation != "yes" ]]; then
  echo "عملیات لغو شد."
  exit 1
fi

# ایجاد پارتیشن‌ها
echo "ایجاد پارتیشن‌ها..."
parted -s /dev/sda mklabel gpt
parted -s /dev/sda mkpart primary fat32 1MiB 513MiB
parted -s /dev/sda mkpart primary ext4 513MiB 100%

# انتظار برای تایید استفاده از /dev/sda2
echo "لطفاً از /dev/sda2 برای نصب اوبونتو استفاده شود. در صورتی که موافقید، برای ادامه یکبار yes را وارد کنید."
read -p "Proceed anyway? (yes/no): " proceed_confirmation
if [[ $proceed_confirmation != "yes" ]]; then
  echo "عملیات لغو شد."
  exit 1
fi

# فرمت پارتیشن‌ها
echo "فرمت دهی به پارتیشن‌ها..."
mkfs.vfat -F 32 /dev/sda1
mkfs.ext4 /dev/sda2

# مانت پارتیشن‌ها
echo "مانت پارتیشن‌ها..."
mkdir -p /mnt
mount /dev/sda2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

# نصب اوبونتو از مخزن اصلی اوبونتو
echo "نصب اوبونتو $selected_version..."
debootstrap --arch amd64 $selected_version /mnt http://archive.ubuntu.com/ubuntu/

# تنظیمات fstab
echo "تنظیم fstab..."
echo "UUID=$(blkid -s UUID -o value /dev/sda2) / ext4 errors=remount-ro 0 1" | tee /mnt/etc/fstab
echo "UUID=$(blkid -s UUID -o value /dev/sda1) /boot/efi vfat umask=0077 0 1" | tee -a /mnt/etc/fstab

# chroot به سیستم جدید
echo "chroot به سیستم جدید..."
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
chroot /mnt /bin/bash << 'EOF'
# به‌روزرسانی پکیج‌ها
apt-get update
# نصب کرنل و GRUB
apt-get install -y linux-image-generic grub-efi-amd64
# نصب GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck
update-grub
# تنظیم رمز عبور برای کاربر root
echo "root:password" | chpasswd
EOF

# پایان عملیات
umount /mnt/dev
umount /mnt/proc
umount /mnt/sys
umount /mnt/boot/efi
umount /mnt

echo "نصب اوبونتو $selected_version به پایان رسید. سیستم را مجدداً راه‌اندازی کنید."

# پیشنهاد برای راه‌اندازی مجدد
read -p "آیا می‌خواهید سیستم را اکنون مجدداً راه‌اندازی کنید؟ (yes/no): " reboot_confirmation
if [[ $reboot_confirmation == "yes" ]]; then
  reboot
else
  echo "سیستم نیاز به راه‌اندازی مجدد دارد تا تغییرات اعمال شوند."
fi
