export 'desmos_calculator_embed_stub.dart'
    if (dart.library.html) 'desmos_calculator_embed_web.dart'
    if (dart.library.io) 'desmos_calculator_embed_io.dart';
