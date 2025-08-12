
[توضیحات فارسی](/README-fa.md)

<p align="center">
  <img width="600px" src="https://i.postimg.cc/L8mBhMP5/Chat-GPT-Image-Aug-11-2025-01-00-36-AM.png" alt="لوگوی Tunn3l">

**اسکریپت پیشرفته مدیریت تونل VXLAN برای سرورهای لینوکسی - بر پایه Lena Tunnel (این پروژه یک فورک از Lena Tunnel است)**

[![](https://img.shields.io/github/v/release/RealCuf/Tunn3l.svg)](https://github.com/RealCuf/Tunn3l/releases)
[![Downloads](https://img.shields.io/github/downloads/RealCuf/Tunn3l/total.svg)](#)
![Languages](https://img.shields.io/github/languages/top/RealCuf/Tunn3l.svg?color=green)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?color=lightgrey)](https://opensource.org/licenses/MIT)


> **سلب مسئولیت:** این پروژه فقط برای یادگیری شخصی و ارتباطات است. لطفاً از آن برای مقاصد غیرقانونی استفاده نکنید و در محیط تولید (Production) اجرا نکنید.

**اگر این پروژه برایتان مفید بود، می‌توانید به آن یک** :star2: **بدهید**

---

## **Tunn3l چیست؟**

> Tunn3l یک راهکار سریع، سبک و هوشمند تونل‌سازی است که بر پایه فناوری قدرتمند VXLAN ساخته شده و با مدیریت خودکار ترافیک از طریق HAProxy ترکیب شده است. این ابزار برای ایجاد و مدیریت خودکار تونل‌های امن شبکه بدون پیکربندی‌های پیچیده طراحی شده و داده‌ها را با کمترین تأخیر و بیشترین بازده منتقل می‌کند. Tunn3l انتخابی ایده‌آل برای حرفه‌ای‌هایی است که به دنبال یک راهکار شبکه پایدار، کم‌مصرف و با کارایی بالا هستند.

## **ویژگی‌های کلیدی Tunn3l (نسخه جدید):**

🚀 **تونل‌سازی مبتنی بر VXLAN:** استفاده از مجازی‌سازی پیشرفته شبکه برای ایجاد تونل‌های امن، پایدار و پرسرعت بین سرورها.

🌐 **پشتیبانی از IPv4 و IPv6:** تونل‌سازی بدون مشکل حتی در شرایط محدودیت IPv6 یا محیط‌های دوگانه (Dual-Stack).

⚙️ **نصب آسان با HAProxy:** ایجاد و مدیریت خودکار تونل‌ها با استفاده از لودبالانسر قدرتمند HAProxy.

💡 **مصرف کم منابع:** طراحی‌شده برای عملکرد بهینه با کمترین میزان استفاده از CPU و حافظه.

📊 **رابط کاربری دیالوگ تعاملی:** پیکربندی کامل تونل، انتخاب نقش، تنظیم IP و مدیریت سرویس‌ها در یک رابط کاربری ساده مبتنی بر ترمینال.

🔄 **مدیریت خودکار سرویس‌ها:** ایجاد سرویس‌ها و تایمرهای هوشمند systemd برای حفظ پایداری اتصال.

📡 **پایش هوشمند تونل:** بررسی مداوم اتصال VXLAN با استفاده از اسکریپت مانیتورینگ Ping و ثبت نتایج.

🛠 **مدیریت پیشرفته:** امکان ویرایش، حذف یا بروزرسانی اسکریپت مستقیماً از GitHub تنها با چند کلیک.

⚡ **پشتیبانی از BBR:** نصب با یک کلیک الگوریتم کنترل ازدحام BBR برای بهبود سرعت و کاهش تأخیر.

---

## **نصب**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/RealCuf/Tunn3l/refs/heads/main/install.sh)
```

## **پایش تونل**
> این اسکریپت یک ابزار کمکی به نام ping_monitor.sh نصب می‌کند که هر ۳۰ ثانیه یک‌بار IP سمت مقابل تونل را پینگ کرده و نتیجه را در این مسیر ثبت می‌کند:

```
/var/log/vxlan_ping.log
```

برای مشاهده زنده لاگ‌ها:

```bash
tail -f /var/log/vxlan_ping.log
```

برای اجرای دستی اسکریپت مانیتورینگ:
```bash
/usr/local/bin/ping_monitor.sh <remote_ip>
```

---

## **تشکر از**

- [@MrAminiDev](https://github.com/MrAminiDev) برای پروژه اصلی

## Stargazers over Time

[![Stargazers over time](https://starchart.cc/RealCuf/tunn3l.svg?variant=adaptive)](https://starchart.cc/RealCuf/tunn3l)
