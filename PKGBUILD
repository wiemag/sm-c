# Wiesław Magusiak <w.magusiak@gmail.com>
pkgname=sm-c
pkgver=1.1
pkgrel=2
pkgdesc="sendmail connector"
arch=('i686' 'x86_64')
url="http://github.com/wiemag/sm-c"
license=('GPL')
depends=('bash' 'msmtp')
provides=('smtp-forwarder')
conflicts=('msmtp-mta' 'esmtp' 'ssmtp')
# In case of esmtp an ssmtp manual installation is possible.
# The conflicting file is the /usr/bin/sendmail symlink.
replaces=()
backup=()
options=()
install=
changelog=
source=(https://github.com/wiemag/sm-c/archive/v${pkgver}.tar.gz)
noextract=()
md5sums=('2ec6a2ec5e46bf6e5c1cbf59d5ac5a9d')
package() {
	cd "$srcdir/${pkgname}-$pkgver"
	mkdir -p ${pkgdir}/usr/bin/
	cp sm-c.sh ${pkgdir}/usr/bin/
	cd ${pkgdir}/usr/bin/
	ln -s sm-c.sh sendmail
}
