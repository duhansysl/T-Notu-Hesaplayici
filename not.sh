#!/usr/bin/env bash
#
# ======================================================================
#
#  KOCAELİ ÜNİVERSİTESİ T-standart Notu Hesaplayıcı
#
#  Copyright (C) 2025 duhansysl
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# ======================================================================
#
# shellcheck disable=SC2012,SC2024,SC2144
#

# Gerekli tanımlamalar
gecme_notu="40"    # Üniversitenin belirlemiş olduğu minimum geçme notu

# Kullanıcıdan gerekli bilgileri al
clear; echo
read -p " Yarıyıl içi ortalaması  : " yariyil_ici
read -p " Yarıyıl sonu notu       : " yariyil_sonu
read -p " Yarıyıl sonu yüzdesi    : " yariyil_sonu_yuzde
read -p " Sınıf ortalaması (DSN)  : " sinif_ortalama
read -p " Standart sapma          : " standart_sapma

yariyil_ici_yuzde=$(echo "scale=10; 100 - $yariyil_sonu_yuzde" | bc -l)

# Yarıyıl içi ve yarıyıl sonu notlarını yüzdelik ağırlıklarla hesapla
yariyil_ici_agirlikli=$(echo "scale=10; $yariyil_ici * $yariyil_ici_yuzde / 100" | bc -l)
yariyil_sonu_agirlikli=$(echo "scale=10; $yariyil_sonu * $yariyil_sonu_yuzde / 100" | bc -l)

# Toplam notu hesapla
toplam_not=$(echo "scale=10; $yariyil_ici_agirlikli + $yariyil_sonu_agirlikli" | bc -l)

# T notunu hesapla
t_notu=$(echo "scale=10; (($toplam_not - $sinif_ortalama) / $standart_sapma) * 10 + 50" | bc -l)

# awk ile iki basamaklı formata çevir
t_notu_formatli=$(echo "$t_notu" | awk '{printf "%.2f", $1}')

# Sınıf durumları ve aralıkları (DSN)
sinif_durumlar=("Mükemmel" "Çok İyi" "İyi" "Ortanın Üstü" "Orta" "Zayıf" "Kötü")
sinif_min=(70.01 62.51 57.51 52.51 47.51 42.51 0.00)
sinif_max=(79.99 70.00 62.50 57.50 52.50 47.50 42.49)

# Harf notları ve aralıkları
harf_notlari=("FF" "FD" "DD" "DC" "CC" "CB" "BB" "BA" "AA")
harf_min=(
    "0.00 24.00 29.00 34.00 39.00 44.00 49.00 54.00 59.00"   # Mükemmel
    "0.00 26.00 31.00 36.00 41.00 46.00 51.00 56.00 61.00"   # Çok İyi
    "0.00 28.00 33.00 38.00 43.00 48.00 53.00 58.00 63.00"   # İyi
    "0.00 30.00 35.00 40.00 45.00 50.00 55.00 60.00 65.00"   # Ortanın Üstü
    "0.00 32.00 37.00 42.00 47.00 52.00 57.00 62.00 67.00"   # Orta
    "0.00 34.00 39.00 44.00 49.00 54.00 59.00 64.00 69.00"   # Zayıf
    "0.00 36.00 41.00 46.00 51.00 56.00 61.00 66.00 71.00"   # Kötü
)

harf_max=(
    "23.99 28.99 33.99 38.99 43.99 48.99 53.99 58.99 100.00"   # Mükemmel
    "25.99 30.99 35.99 40.99 45.99 50.99 55.99 60.99 100.00"   # Çok İyi
    "27.99 32.99 37.99 42.99 47.99 52.99 57.99 62.99 100.00"   # İyi
    "29.99 34.99 39.99 44.99 49.99 54.99 59.99 64.99 100.00"   # Ortanın Üstü
    "31.99 36.99 41.99 46.99 51.99 56.99 61.99 66.99 100.00"   # Orta
    "33.99 38.99 43.99 48.99 53.99 58.99 63.99 68.99 100.00"   # Zayıf
    "35.99 40.99 45.99 50.99 55.99 60.99 65.99 70.99 100.00"   # Kötü
)


# DSN'ye göre sınıf durumunu belirle
sinif_durum=""
for i in "${!sinif_durumlar[@]}"; do
    if (( $(echo "$sinif_ortalama >= ${sinif_min[i]}" | bc -l) )) && (( $(echo "$sinif_ortalama < ${sinif_max[i]}" | bc -l) )); then
        sinif_durum="${sinif_durumlar[i]}"
        not_index=$i
        break
    fi
done

if [ -z "$sinif_durum" ]; then
    echo "Geçersiz sınıf ortalaması (DSN)."
    exit 1
fi

# T notuna göre harf notunu belirle
IFS=' ' read -r -a min_values <<< "${harf_min[not_index]}"
IFS=' ' read -r -a max_values <<< "${harf_max[not_index]}"
harf_notu=""

for j in "${!harf_notlari[@]}"; do
    if (( $(echo "$t_notu >= ${min_values[j]}" | bc -l) )) && (( $(echo "$t_notu <= ${max_values[j]}" | bc -l) )); then
        harf_notu="${harf_notlari[j]}"
        break
    fi
done

# Bulunduğunuz not aralığını yazdır
IFS=' ' read -r -a min_values <<< "${harf_min[not_index]}"
IFS=' ' read -r -a max_values <<< "${harf_max[not_index]}"

# Not aralığı hesapla
for j in "${!harf_notlari[@]}"; do
    if [ "$harf_notu" == "${harf_notlari[j]}" ]; then
		not_aralik="${min_values[j]} - ${max_values[j]}"
        break
    fi
done

# Başarı durumu hesabı
if [[ "$harf_notu" == "DC" ]]; then
    kosul_durumu="Koşullu"
elif [[ "$harf_notu" == "DD" ]] || [[ "$harf_notu" == "FD" ]] || [[ "$harf_notu" == "FF" ]]; then
	kosul_durumu="Başarısız"
else
    kosul_durumu="Başarılı"
fi

# Yarıyıl sonu 40 altı hesabı
if [[ "$yariyil_sonu" < "$gecme_notu" ]]; then
harf_notu="FF"
kosul_durumu="Başarısız"
fi

# Aldığınız T notunu, harf notunu ve sınıf durumunu yazdır
clear
echo "-----------------------------------------------------------"
echo
echo " Sınıf Başarı Durumu        : $sinif_durum"
echo " Bulunduğunuz Not Aralığı   : $not_aralik"
echo " T-standart Notu            : $t_notu_formatli"
echo " Aldığınız Harf Notu        : $harf_notu"
echo " Başarı Durumu              : $kosul_durumu"
echo
echo "-----------------------------------------------------------"