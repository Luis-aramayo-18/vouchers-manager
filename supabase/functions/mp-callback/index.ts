
Deno.serve(async (req: Request) => {
  try {
    const url = new URL(req.url);
    const code = url.searchParams.get('code');
    const state = url.searchParams.get('state');

    if (!code || !state) {
      console.error('Faltan parámetros "code" o "state" en la URL de callback.');
      return new Response(
        '<h1>Error: Faltan parámetros de autorización. Por favor, intente el proceso de vinculación de nuevo.</h1>',
        {
          status: 400,
          headers: {
            'Content-Type': 'text/html',
          },
        },
      );
    }

    // 2. Construir el Deep Link que la aplicación Flutter interceptará.
    // El Deep Link DEBE COINCIDIR con el <data android:scheme="vouchersapp"...> 
    // y <data android:host="mp_auth"...> de su AndroidManifest.xml.
    const DEEP_LINK_SCHEME = 'vouchersapp';
    const DEEP_LINK_HOST = 'mp_auth';
    
    // El Deep Link se ve así: vouchersapp://mp_auth?code=...&state=...
    const deepLinkUrl = `${DEEP_LINK_SCHEME}://${DEEP_LINK_HOST}?code=${code}&state=${state}`;

    // 3. Devolver una respuesta HTTP 303 (See Other) para forzar la redirección del navegador
    // al Deep Link de la aplicación.
    return new Response(null, {
      status: 303, // Código estándar para "ver otro" y forzar redirección
      headers: {
        'Location': deepLinkUrl,
        'Content-Type': 'text/html',
      },
    });

  } catch (error) {
    console.error('Error general en mp-callback:', error);
    // CORRECCIÓN 2: Usamos una aserción de tipo para tratar 'error' como 'Error' y acceder a '.message' (evita error 18046).
    return new Response(
      `<h1>Error interno: ${(error as Error).message}</h1><p>Por favor, contacte a soporte.</p>`,
      {
        status: 500,
        headers: {
          'Content-Type': 'text/html',
        },
      },
    );
  }
});