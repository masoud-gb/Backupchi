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
su -c "parted -s /dev/sda mklabel gpt"
su -c "parted -s /dev/sda mkpart primary fat32 1MiB 513MiB"
su -c "parted -s /dev/sda mkpart primary ext4 513MiB 100%"

# فرمت پارتیشن‌ها
echo "فرمت دهی به پارتیشن‌ها..."
su -c "mkfs.vfat -F 32 /dev/sda1"
su -c "mkfs.ext4 /dev/sda2"

# مانت پارتیشن‌ها
echo "مانت پارتیشن‌ها..."
su -c "mount /dev/sda2 /mnt"
su -c "mkdir -p /mnt/boot/efi"
su -c "mount /dev/sda1 /mnt/boot/efi"

# نصب اوبونتو از مخزن اصلی اوبونتو
echo "نصب اوبونتو $selected_version..."
su -c "debootstrap --arch amd64 $selected_version /mnt http://archive.ubuntu.com/ubuntu/"

# تنظیمات fstab
echo "تنظیم fstab..."
echo "UUID=$(su -c "blkid -s UUID -o value /dev/sda2") / ext4 errors=remount-ro 0 1" | su -c "tee /mnt/etc/fstab"
echo "UUID=$(su -c "blkid -s UUID -o value /dev/sda1") /boot/efi vfat umask=0077 0 1" | su -c "tee -a /mnt/etc/fstab"

# chroot به سیستم جدید
echo "chroot به سیستم جدید..."
su -c "mount --bind /dev /mnt/dev"
su -c "mount --bind /proc /mnt/proc"
su -c "mount --bind /sys /mnt/sys"
su -c "chroot /mnt /bin/bash << 'EOF'
# به‌روزرسانی پکیج‌ها
apt-get update
# نصب کرنل و GRUB
apt-get install -y linux-image-generic grub-efi-amd64
# نصب GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck
update-grub
# تنظیم رمز عبور برای کاربر root
echo "root:password" | chpasswd
EOF"

# پایان عملیات
su -c "umount /mnt/dev"
su -c "umount /mnt/proc"
su -c "umount /mnt/sys"
su -c "umount /mnt/boot/efi"
su -c "umount /mnt"

echo "نصب اوبونتو $selected_version به پایان رسید. سیستم را مجدداً راه‌اندازی کنید."

# پیشنهاد برای راه‌اندازی مجدد
read -p "آیا می‌خواهید سیستم را اکنون مجدداً راه‌اندازی کنید؟ (yes/no): " reboot_confirmation
if [[ $reboot_confirmation == "yes" ]]; then
  su -c "reboot"
else
  echo "سیستم نیاز به راه‌اندازی مجدد دارد تا تغییرات اعمال شوند."
fi
