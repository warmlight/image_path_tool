import 'package:build/build.dart';
import 'package:image_path_tool/generator.dart';
import 'package:source_gen/source_gen.dart';

Builder imagePathToolBuilder(BuilderOptions options) =>
    LibraryBuilder(ImagePathToolGenerator(), generatedExtension: '.image.dart');
