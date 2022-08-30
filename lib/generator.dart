import 'dart:io';

import 'package:image_path_tool/image_path_tool.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';

/// 注解代码生成器
/// 创建一个类继承自 GeneratorForAnnoration 的类，实现抽象方法（具体的逻辑功能）
class ImagePathToolGenerator extends GeneratorForAnnotation<ImagePathTool> {
  // String _codeContent = '';
  // Map<String, dynamic> imagesInfo = <String, dynamic>{};
  Map<String, String> svgImagesPath = <String, String>{};
  Map<String, String> pngImagesPath = <String, String>{};

  @override

  /// element: 被注解的类/方法等的详细信息
  /// annotation: 注解的详细信息, 一般用来获取注解的参数信息
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    String pngCodeContent = '';
    String svgCodeContent = '';

    /// 图片文件路径
    /// peek：
    /// Reads [field] from the constant as another constant value.
    /// Unlike [read], returns `null` if the field is not found.
    String imagePath = annotation.peek('pathName')?.stringValue ?? '';
    if (!imagePath.endsWith('/')) {
      imagePath = '$imagePath/';
    }

    /// 生成新的Dart文件名称
    var newClassName = annotation.peek('newClassName')?.stringValue;

    /// 遍历处理图片资源路径
    handleFile(imagePath);

    svgImagesPath.forEach((key, value) {
      svgCodeContent = '$svgCodeContent\n\t\t\t\tstatic const String $key = \'$value\';';
    });

    pngImagesPath.forEach((key, value) {
      pngCodeContent = '$pngCodeContent\n\t\t\t\tstatic const String $key = \'$value\';';
    });

    return 'class R_Png{\n'
        '    $pngCodeContent\n'
        '}\n'
        'class R_Svg{\n'
        '    $svgCodeContent\n'
        '}';

    // imagesInfo.forEach((key, value) {
    //   String filePath = value['path'];
    //   _codeContent = '$_codeContent\n\t\t\t\tstatic const String $key = \'$filePath\';';
    // });

    /// 返回生成的代码文件
    // return 'class $newClassName{\n'
    //     '    $_codeContent\n'
    //     '}';
  }

  void handleSvgFile(String fileName, String filePath) {
    String tKey = fileName.replaceAll(RegExp('.svg'), '').replaceAll(RegExp('-'), '_');
    if (svgImagesPath.keys.contains(tKey)) {
      // 下划线替换导致重名 就将中划线改成两个下划线
      tKey = fileName.replaceAll(RegExp('.svg'), '').replaceAll(RegExp('-'), '__');
    }
    svgImagesPath[tKey] = filePath;
  }

  void handlePngFile(String fileName, String filePath) {
    String tKey = fileName.replaceAll(RegExp('.png'), '').replaceAll(RegExp('-'), '_');
    if (pngImagesPath.keys.contains(tKey)) {
      // 下划线替换导致重名 就将中划线改成两个下划线
      tKey = fileName.replaceAll(RegExp('.png'), '').replaceAll(RegExp('-'), '__');
    }
    pngImagesPath[tKey] = filePath;
  }

  void handleFile(String path) {
    final Directory directory = Directory(path);

    for (FileSystemEntity file in directory.listSync()) {
      FileSystemEntityType type = file.statSync().type;
      if (type == FileSystemEntityType.directory) {
        /// 递归文件夹
        handleFile('${file.path}/');
      } else if (type == FileSystemEntityType.file) {
        String filePath = file.path;
        String fileExtension = filePath.split(".").last.toLowerCase();


        if (fileExtension != 'png' && fileExtension != 'svg') continue;

        String keyName = filePath.trim().toLowerCase();

        String tKey = keyName.replaceAll(RegExp(path.toLowerCase()), '');
        if (fileExtension == 'png') {
          handlePngFile(tKey, filePath);
        } else {
          handleSvgFile(tKey, filePath);
        }

        // String tKey = keyName
        //     .replaceAll(RegExp(path.toLowerCase()), '')
        //     .replaceAll(RegExp('.png'), '')
        //     .replaceAll(RegExp('.svg'), '')
        //     .replaceAll(RegExp('-'), '_');

        // if (imagesInfo.keys.contains(tKey)) {
        //   if (imagesInfo[tKey]['extension'] == fileExtension) {
        //     // 下划线替换导致重名 就将中划线改成两个下划线
        //     tKey = filePath
        //         .trim()
        //         .toLowerCase()
        //         .replaceAll(RegExp(path.toLowerCase()), '')
        //         .replaceAll(RegExp('.png'), '')
        //         .replaceAll(RegExp('.svg'), '')
        //         .replaceAll(RegExp('-'), '__');
        //   } else {
        //     // 如果 png/svg中有重名 就加上图片类型后缀
        //     Map<String, String> preImageValue = imagesInfo[tKey];
        //     imagesInfo.remove(tKey);
        //     String preImageKey = tKey + '_${preImageValue['extension']}';
        //     imagesInfo[preImageKey] = preImageValue;
        //     tKey += '_$fileExtension';
        //   }
        // }

        // imagesInfo[tKey] = {
        //   'extension': fileExtension,
        //   'path': filePath,
        // };
      }
    }
  }

  // void handleFile(String path) {
  //   final Directory directory = Directory(path);

  //   for (FileSystemEntity file in directory.listSync()) {
  //     FileSystemEntityType type = file.statSync().type;
  //     if (type == FileSystemEntityType.directory) {
  //       /// 递归文件夹
  //       handleFile('${file.path}/');
  //     } else if (type == FileSystemEntityType.file) {
  //       String filePath = file.path;
  //       String fileExtension = filePath.split(".").last.toLowerCase();

  //       String keyName = filePath.trim().toLowerCase();

  //       if (fileExtension != 'png' && fileExtension != 'svg') continue;

  //       String tKey = keyName
  //           .replaceAll(RegExp(path.toLowerCase()), '')
  //           .replaceAll(RegExp('.png'), '')
  //           .replaceAll(RegExp('.svg'), '')
  //           .replaceAll(RegExp('-'), '_');

  //       if (imagesInfo.keys.contains(tKey)) {
  //         if (imagesInfo[tKey]['extension'] == fileExtension) {
  //           // 下划线替换导致重名 就将中划线改成两个下划线
  //           tKey = filePath
  //               .trim()
  //               .toLowerCase()
  //               .replaceAll(RegExp(path.toLowerCase()), '')
  //               .replaceAll(RegExp('.png'), '')
  //               .replaceAll(RegExp('.svg'), '')
  //               .replaceAll(RegExp('-'), '__');
  //         } else {
  //           // 如果 png/svg中有重名 就加上图片类型后缀
  //           Map<String, String> preImageValue = imagesInfo[tKey];
  //           imagesInfo.remove(tKey);
  //           String preImageKey = tKey + '_${preImageValue['extension']}';
  //           imagesInfo[preImageKey] = preImageValue;
  //           tKey += '_$fileExtension';
  //         }
  //       }

  //       imagesInfo[tKey] = {
  //         'extension': fileExtension,
  //         'path': filePath,
  //       };
  //     }
  //   }
  // }
}
