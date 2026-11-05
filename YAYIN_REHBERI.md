# Parion - Otomatik Sürüm Yayınlama Rehberi

Bu doküman, Parion uygulamanızın yeni bir sürümünü kendi başınıza, adım adım nasıl Google Play Store'a yükleyeceğinizi anlatmaktadır. Projenizde yüklü ve yapılandırılmış olan **Fastlane** altyapısı sayesinde işlemler oldukça hızlı ve kolaydır.

## Adım 1: Sürüm Numarasını Güncellemek

Uygulamanın yeni sürümünü belirtmek için öncelikle sürüm numarasını arttırmanız gerekir.

1. Proje ana dizinindeki `pubspec.yaml` dosyasını açın.
2. `version:` ile başlayan satırı bulun.
   *(Örnek: `version: 1.0.17+17`)*
3. Buradaki numaraları mantıklı bir şekilde arttırın. Örneğin, basit bir güncelleme ise sondaki sayıyı ve `+` işaretinden sonraki yapı numarasını (build number) bir artırın:
   *(Örnek yeni sürüm: `version: 1.0.18+18`)*
4. Dosyayı kaydedin.

## Adım 2: Sürüm Notunu (Changelog) Hazırlamak

Kullanıcıların Google Play Store'da göreceği "Yenilikler" metnini girmek için:

1. `android/fastlane/metadata/android/tr-TR/changelogs/` klasörüne gidin.
2. İçerisine `pubspec.yaml` dosyasında verdiğiniz yapı numarası (build number, yani `+` sonrasındaki sayı) ile aynı ada sahip bir `.txt` dosyası oluşturun. Örneğin `18.txt`.
3. Dosyanın içerisine sürüm notunuzu yazın. 
   *(Örnek: `Arayüz geliştirmeleri ve performans iyileştirmeleri yapıldı.`)*
4. İsteğe bağlı olarak, her zaman kullanılabilecek genel bir not için aynı klasördeki `default.txt` dosyasının içeriğini de güncelleyebilirsiniz.

## Adım 3: Uygulamayı Derlemek (Build)

Uygulamanızı Google Play'in kabul edeceği Android App Bundle (.aab) formatında derlemeniz gerekir.

1. Terminalinizi (veya komut satırınızı) açıp projenin **ana dizinine** (`e:\KODLAMA\Parion`) gidin.
2. Aşağıdaki komutu çalıştırarak derleme işlemini başlatın:
   ```bash
   flutter build appbundle --release
   ```
3. İşlem tamamlandığında ekranda "Built build\app\outputs\bundle\release\app-release.aab" mesajını göreceksiniz. (Bu işlem bilgisayarınızın hızına göre birkaç dakika sürebilir).

## Adım 4: Fastlane ile Play Store'a Göndermek

Derlediğiniz paketi ve yazdığınız sürüm notlarını otomatik olarak Play Store'a göndermek için Fastlane kullanacaksınız.

1. Terminalinizden `android` klasörünün içine girin:
   ```bash
   cd android
   ```
2. Aşağıdaki Fastlane komutunu çalıştırın:
   ```bash
   bundle exec fastlane android upload
   ```
3. Komut çalıştıktan sonra, Fastlane sizin yerinize şunları yapacaktır:
   - Google Play Developer Console'a otomatik giriş yapar.
   - Yazdığınız `18.txt` dosyasındaki sürüm notlarını okur.
   - Oluşturduğunuz `app-release.aab` dosyasını bulur ve Production (Üretim) kanalına yükler.
   - Yükleme bitince "Successfully finished the upload to Google Play" mesajı verecektir.

**Tebrikler!** Yeni sürüm başarıyla incelemeye gönderilmiştir. Google incelemesi tamamlandığında (genellikle birkaç saat ila birkaç gün sürer) kullanıcılarınız güncellemeyi alacaktır.
