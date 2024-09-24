import 'dart:io';

import 'package:image_path_tool/image_path_tool.dart';
import 'package:build/build.dart';
import 'package:tuple/tuple.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';

/// 注解代码生成器
/// 创建一个类继承自 GeneratorForAnnoration 的类，实现抽象方法（具体的逻辑功能）
class ImagePathToolGenerator extends GeneratorForAnnotation<ImagePathTool> {
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

    /// 遍历处理图片资源路径
    handleFile(imagePath);

    svgImagesPath.forEach((key, value) {
      svgCodeContent = '$svgCodeContent\n\t\t\t\tstatic const String $key = \'$value\';';
    });

    pngImagesPath.forEach((key, value) {
      pngCodeContent = '$pngCodeContent\n\t\t\t\tstatic const String $key = \'$value\';';
    });

    /// 查找未使用的图片
    findNoUseImageInPath(imagePath);

    return 'class R_Png{\n'
        '    $pngCodeContent\n'
        '}\n'
        'class R_Svg{\n'
        '    $svgCodeContent\n'
        '}';
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
      }
    }
  }

  void findNoUseImageInPath(String path) {
    // 所有图片名字
    List<String> allImagesName = [
      ...svgImagesPath.keys,
      ...pngImagesPath.keys,
    ];

    // 所有图片路径
    List<String> allImagePath = [
      ...svgImagesPath.values,
      ...pngImagesPath.values,
    ];

    for (var file in Directory('${Directory.current.path}/$path').listSync(recursive: true)) {
      // 返回未使用的图片
      // 随着每一次遍历，图片集合会被更新，剔除那些已经使用的图片, 直到所有文件遍历完成
      Tuple2? result = filterNoUseImageInFile(file: file, imageNameList: allImagesName, imagePathList: allImagePath);
      if (result?.item1.isNotEmpty == true) {
        allImagesName = result!.item1;
      }
      if (result?.item2.isNotEmpty == true) {
        allImagePath = result!.item2;
      }
    }

    // 根据图片名称找到图片路径
    List nameMapPath = [];
    if (allImagesName.isNotEmpty) {
      for (var element in allImagesName) {
        String? path = svgImagesPath[element] ?? pngImagesPath[element];
        if (path != null) {
          nameMapPath.add(path);
        }
      }
    } else {}

    // 未被使用的图片名 和 未被使用的图片路径 取交集，得到未被使用的图片
    List<String> intersection = allImagePath.toSet().intersection(nameMapPath.toSet()).toList();
    if (intersection.isNotEmpty) {
      String logInfo = '😈😈 下列图片可能未使用，如确定未被使用，可清理减小包体积 😈😈 \n';
      for (var element in intersection) {
        final File imageFile = File(element);
        if (imageFile.existsSync()) {
          // 获取文件大小
          int fileSize = imageFile.lengthSync();
          logInfo += '$element,  大小：${formatFileSize(fileSize)}\n';
        } else {}
      }
      print(logInfo);
    }
  }

  // 返回未使用的图片名称
  filterNoUseImageInFile({required FileSystemEntity file, required List<String> imageNameList, required List<String> imagePathList}) {
    List<String> nameCopy = [];
    nameCopy.addAll(imageNameList);
    List<String> pathCopy = [];
    pathCopy.addAll(imagePathList);

    if (file is File && file.path.endsWith('.dart')) {
      // 读取文件内容
      String content = file.readAsStringSync();
      // 遍历所有图片名称，如果文件内容包含图片名称，则从所有图片名称中移除
      for (var imageName in imageNameList) {
        if (content.contains(imageName)) {
          nameCopy.remove(imageName);
        }
      }
      for (var imagePath in imagePathList) {
        if (content.contains(imagePath)) {
          pathCopy.remove(imagePath);
        }
      }
      return Tuple2(nameCopy, pathCopy);
    }
    return null;
  }

  String formatFileSize(int bytes) {
    const int kb = 1024; // 1 KB = 1024 Bytes
    const int mb = kb * 1024; // 1 MB = 1024 KB

    if (bytes < kb) {
      return '$bytes Bytes';
    } else if (bytes < mb) {
      return '${(bytes / kb).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / mb).toStringAsFixed(2)} MB';
    }
  }
}
