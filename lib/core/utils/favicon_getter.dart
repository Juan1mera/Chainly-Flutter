class FaviconGetter {
  /// Returna la url para obtener el favicon segun la api de google para favicons
  /// 
  /// la [url] puede ser la url completa o solo el dominio
  /// el [size] por defecto es 128 
  static String getFaviconUrl(String url, {int size = 128}) {
    String normalizedUrl = url.trim();
    if (normalizedUrl.isEmpty) return '';

    if (!normalizedUrl.startsWith('http')) {
      normalizedUrl = 'https://$normalizedUrl';
    }

    return "https://www.google.com/s2/favicons?sz=$size&domain_url=$normalizedUrl";
  }
}
