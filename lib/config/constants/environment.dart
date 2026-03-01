/// Constantes globales de la aplicación Fashion Store
class AppConstants {
  // ─── Supabase ───
  static const supabaseUrl = 'https://qquzifirnqodldyhbelv.supabase.co';

  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSI'
      'sInJlZiI6InFxdXppZmlybnFvZGxkeWhiZWx2Iiwicm9sZSI6ImFub24iLCJp'
      'YXQiOjE3Njc4NTU2NTksImV4cCI6MjA4MzQzMTY1OX0.UvkrWFNt1emb2S-5'
      '-J2pfgpTjNI_ngTblJy6Xm9IHtQ';

  // ─── Stripe (solo publishable key — secret key queda en el backend) ───
  static const stripePublishableKey =
      'pk_test_51SLLdu1fszVBSeCFXMknv7yYJPbhoKHlbQNuKtx4o'
      'vpC3Cw99sAOZSnRM8SiC8bQ9QtOD4Ww5hZDZkPJDOzkZJNv00C8injlTk';

  // ─── Backend URLs ───
  static const backendBaseUrl =
      'https://mccook8g4sw8kg8kw8kkwoko.victoriafp.online';

  // ─── Supabase Edge Functions ───
  static const supabaseFunctionsUrl =
      'https://qquzifirnqodldyhbelv.supabase.co/functions/v1';

  // ─── Storage ───
  static const storageBucket = 'products-images';

  // ─── Paginación ───
  static const productsPerPage = 24;
  static const ordersPerPage = 20;

  // ─── Compresión de imágenes ───
  static const imageMaxWidth = 1024;
  static const imageMaxHeight = 1024;
  static const imageQuality = 80;

  // ─── Tiempos ───
  static const searchDebounceMs = 300;
  static const newsletterPopupDelayMs = 5000;
  static const cancelOrderTimeoutHours = 2;
  static const returnDeadlineDays = 14;
}
