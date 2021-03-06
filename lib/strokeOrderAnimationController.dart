import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:stroke_order_animator/strokeOrderAnimator.dart';
import 'package:svg_path_parser/svg_path_parser.dart';

/// A ChangeNotifier that controls the behaviour of a stroke order diagram.
/// It must be passed as an argument to a [StrokeOrderAnimator] that handles
/// the actual presentation of the diagram. It can be consumed by the
/// [StrokeOrderAnimator] and an app to allow for synchronization of, e.g.,
/// control buttons with the animations.
class StrokeOrderAnimationController extends ChangeNotifier {
  String _strokeOrder;
  final TickerProvider _tickerProvider;
  List<int> _radicalStrokes;
  List<int> get radicalStrokes => _radicalStrokes;

  int _nStrokes;
  int get nStrokes => _nStrokes;
  int _currentStroke = 0;
  int get currentStroke => _currentStroke;
  List<Path> _strokes;
  List<Path> get strokes => _strokes;
  List<List<List<int>>> medians;

  AnimationController _strokeAnimationController;
  AnimationController get strokeAnimationController =>
      _strokeAnimationController;
  AnimationController _hintAnimationController;
  AnimationController get hintAnimationController => _hintAnimationController;
  bool _isAnimating = false;
  bool get isAnimating => _isAnimating;
  bool _isQuizzing = false;
  bool get isQuizzing => _isQuizzing;
  double _strokeAnimationSpeed = 1;
  double _hintAnimationSpeed = 3;

  bool _showStroke;
  bool _showOutline;
  bool _showMedian;
  bool _highlightRadical;

  bool get showStroke => _showStroke;
  bool get showOutline => _showOutline;
  bool get showMedian => _showMedian;
  bool get highlightRadical => _highlightRadical;

  Color _strokeColor;
  Color _outlineColor;
  Color _medianColor;
  Color _radicalColor;
  Color _brushColor;
  Color _hintColor;

  Color get strokeColor => _strokeColor;
  Color get outlineColor => _outlineColor;
  Color get medianColor => _medianColor;
  Color get radicalColor => _radicalColor;
  Color get brushColor => _brushColor;
  Color get hintColor => _hintColor;

  double _brushWidth;
  double get brushWidth => _brushWidth;

  int _badTriesThisStroke = 0;
  int _hintAfterStrokes;
  int get hintAfterStrokes => _hintAfterStrokes;

  StrokeOrderAnimationController(
    this._strokeOrder,
    this._tickerProvider, {
    double strokeAnimationSpeed: 1,
    double hintAnimationSpeed: 3,
    bool showStroke: true,
    bool showOutline: true,
    bool showMedian: false,
    bool highlightRadical: false,
    Color strokeColor: Colors.blue,
    Color outlineColor: Colors.black,
    Color medianColor: Colors.black,
    Color radicalColor: Colors.red,
    Color brushColor: Colors.black,
    double brushWidth: 8.0,
    int hintAfterStrokes: 3,
    Color hintColor: Colors.lightBlueAccent,
  }) {
    _strokeAnimationController = AnimationController(
      vsync: _tickerProvider,
    );

    _strokeAnimationController.addStatusListener(_strokeCompleted);

    _hintAnimationController = AnimationController(
      vsync: _tickerProvider,
    );

    _hintAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _hintAnimationController.reset();
      }
    });

    setStrokeOrder(_strokeOrder);
    _setCurrentStroke(0);
    setShowStroke(showStroke);
    setShowOutline(showOutline);
    setShowMedian(showMedian);
    setHighlightRadical(highlightRadical);
    setStrokeColor(strokeColor);
    setOutlineColor(outlineColor);
    setMedianColor(medianColor);
    setRadicalColor(radicalColor);
    setBrushColor(brushColor);
    setBrushWidth(brushWidth);
    setHintAfterStrokes(hintAfterStrokes);
    setHintColor(hintColor);
    setStrokeAnimationSpeed(strokeAnimationSpeed);
    setHintAnimationSpeed(hintAnimationSpeed);
  }

  @override
  dispose() {
    _strokeAnimationController.dispose();
    _hintAnimationController.dispose();
    super.dispose();
  }

  void startAnimation() {
    if (!_isAnimating && !_isQuizzing) {
      if (currentStroke == _nStrokes) {
        _setCurrentStroke(0);
      }
      _isAnimating = true;
      _strokeAnimationController.forward();
      notifyListeners();
    }
  }

  void stopAnimation() {
    if (_isAnimating) {
      _setCurrentStroke(currentStroke + 1);
      _isAnimating = false;
      _strokeAnimationController.reset();
      notifyListeners();
    }
  }

  void startQuiz() {
    if (!_isQuizzing) {
      _isAnimating = false;
      _setCurrentStroke(0);
      _strokeAnimationController.reset();
      _isQuizzing = true;
      notifyListeners();
    }
  }

  void stopQuiz() {
    if (_isQuizzing) {
      _isAnimating = false;
      _strokeAnimationController.reset();
      _isQuizzing = false;
      notifyListeners();
    }
  }

  void nextStroke() {
    if (!_isQuizzing) {
      if (currentStroke == _nStrokes) {
        _setCurrentStroke(1);
      } else if (_isAnimating) {
        _setCurrentStroke(currentStroke + 1);
        _strokeAnimationController.reset();

        if (currentStroke < _nStrokes) {
          _strokeAnimationController.forward();
        } else {
          _isAnimating = false;
        }
      } else {
        if (currentStroke < _nStrokes) {
          _setCurrentStroke(currentStroke + 1);
        }
      }

      notifyListeners();
    }
  }

  void previousStroke() {
    if (!_isQuizzing) {
      if (currentStroke != 0) {
        _setCurrentStroke(currentStroke - 1);
      }

      if (_isAnimating) {
        _strokeAnimationController.reset();
        _strokeAnimationController.forward();
      }

      notifyListeners();
    }
  }

  void reset() {
    _setCurrentStroke(0);
    _isAnimating = false;
    _strokeAnimationController.reset();
    notifyListeners();
  }

  void showFullCharacter() {
    if (!_isQuizzing) {
      _setCurrentStroke(_nStrokes);
      _isAnimating = false;
      _strokeAnimationController.reset();
      notifyListeners();
    }
  }

  void _strokeCompleted(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _setCurrentStroke(currentStroke + 1);
      _strokeAnimationController.reset();
      if (currentStroke < _nStrokes) {
        _strokeAnimationController.forward();
      } else {
        _isAnimating = false;
      }
    }
    notifyListeners();
  }

  void setShowStroke(bool value) {
    _showStroke = value;
    notifyListeners();
  }

  void setShowOutline(bool value) {
    _showOutline = value;
    notifyListeners();
  }

  void setShowMedian(bool value) {
    _showMedian = value;
    notifyListeners();
  }

  void setHighlightRadical(bool value) {
    _highlightRadical = value;
    notifyListeners();
  }

  void setStrokeColor(Color value) {
    _strokeColor = value;
    notifyListeners();
  }

  void setOutlineColor(Color value) {
    _outlineColor = value;
    notifyListeners();
  }

  void setMedianColor(Color value) {
    _medianColor = value;
    notifyListeners();
  }

  void setRadicalColor(Color value) {
    _radicalColor = value;
    notifyListeners();
  }

  void setBrushColor(Color value) {
    _brushColor = value;
    notifyListeners();
  }

  void setHintColor(Color value) {
    _hintColor = value;
    notifyListeners();
  }

  void setBrushWidth(double value) {
    _brushWidth = value;
    notifyListeners();
  }

  void setHintAfterStrokes(int value) {
    _hintAfterStrokes = value;
    notifyListeners();
  }

  void setStrokeAnimationSpeed(double value) {
    _strokeAnimationSpeed = value;
    _setCurrentStroke(currentStroke);
  }

  void setHintAnimationSpeed(double value) {
    _hintAnimationSpeed = value;
    _setCurrentStroke(currentStroke);
  }

  void _setNormalizedStrokeAnimationSpeed(double normFactor) {
    _strokeAnimationController.duration = Duration(
        milliseconds: (normFactor / _strokeAnimationSpeed * 1000).toInt());
  }

  void _setNormalizedHintAnimationSpeed(double normFactor) {
    _hintAnimationController.duration = Duration(
        milliseconds: (normFactor / _hintAnimationSpeed * 1000).toInt());
  }

  void setStrokeOrder(String strokeOrder) {
    final parsedJson = json.decode(_strokeOrder.replaceAll("'", '"'));

    // Transformation according to the makemeahanzi documentation
    _strokes = List.generate(
        parsedJson['strokes'].length,
        (index) => parseSvgPath(parsedJson['strokes'][index]).transform(
            Matrix4(1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 900, 0, 1)
                .storage));

    medians = List.generate(parsedJson['medians'].length, (iStroke) {
      return List.generate(parsedJson['medians'][iStroke].length, (iPoint) {
        return List<int>.generate(
            parsedJson['medians'][iStroke][iPoint].length,
            (iCoordinate) => iCoordinate == 0
                ? parsedJson['medians'][iStroke][iPoint][iCoordinate]
                : parsedJson['medians'][iStroke][iPoint][iCoordinate] * -1 +
                    900);
      });
    });

    if (parsedJson['radStrokes'] != null) {
      _radicalStrokes = List<int>.generate(parsedJson['radStrokes'].length,
          (index) => parsedJson['radStrokes'][index]);
    } else {
      _radicalStrokes = [];
    }
    _nStrokes = _strokes.length;
  }

  void checkStroke(List<Offset> rawPoints) {
    bool strokeIsCorrect = false;

    if (currentStroke < nStrokes) {
      List<Offset> points = [];
      for (var point in rawPoints) {
        if (point != null) {
          points.add(point);
        }
      }

      final currentMedian = medians[currentStroke];

      final medianPath = Path();
      if (currentMedian.length > 1) {
        medianPath.moveTo(
            currentMedian[0][0].toDouble(), currentMedian[0][1].toDouble());
        for (var point in currentMedian) {
          medianPath.lineTo(point[0].toDouble(), point[1].toDouble());
        }
      }

      final strokePath = Path();
      if (points.length > 1) {
        strokePath.moveTo(points[0].dx, points[0].dy);
        for (var point in points) {
          strokePath.lineTo(point.dx, point.dy);
        }
      }

      final medianLength = medianPath.computeMetrics().first.length;
      final strokeLength = strokePath.computeMetrics().first.length;

      // Check whether the drawn stroke is correct
      double startEndMargin = 150;
      List<double> lengthRange = [0.5, 1.5];

      // Be more lenient on short strokes
      if (medianLength < 150) {
        lengthRange = [0.2, 3];
        startEndMargin = 200;
      }

      if ( // Check length of stroke
          strokeLength > lengthRange[0] * medianLength &&
              strokeLength < lengthRange[1] * medianLength &&
              // Check start and end position of stroke
              points.first.dx > currentMedian.first[0] - startEndMargin &&
              points.first.dx < currentMedian.first[0] + startEndMargin &&
              points.first.dy > currentMedian.first[1] - startEndMargin &&
              points.first.dy < currentMedian.first[1] + startEndMargin &&
              points.last.dx > currentMedian.last[0] - startEndMargin &&
              points.last.dx < currentMedian.last[0] + startEndMargin &&
              points.last.dy > currentMedian.last[1] - startEndMargin &&
              points.last.dy < currentMedian.last[1] + startEndMargin &&
              // Check that the stroke has the right direction
              ((distance2D(
                          [points.first.dx, points.first.dy],
                          currentMedian.first
                              .map((e) => e.toDouble())
                              .toList()) <
                      distance2D(
                          [points.last.dx, points.last.dy],
                          currentMedian.first
                              .map((e) => e.toDouble())
                              .toList())) ||
                  (distance2D([
                        points.last.dx,
                        points.last.dy
                      ], currentMedian.last.map((e) => e.toDouble()).toList()) <
                      distance2D(
                          [points.first.dx, points.first.dy],
                          currentMedian.last
                              .map((e) => e.toDouble())
                              .toList())))) {
        strokeIsCorrect = true;
      }

      if (_isQuizzing && currentStroke < nStrokes) {
        if (strokeIsCorrect) {
          _setCurrentStroke(currentStroke + 1);

          if (currentStroke == nStrokes) {
            stopQuiz();
          }

          notifyListeners();
        } else {
          _badTriesThisStroke += 1;
          if (_badTriesThisStroke >= hintAfterStrokes) {
            _hintAnimationController.reset();
            _hintAnimationController.forward();
          }
        }
      }
    }
  }

  void _setCurrentStroke(int value) {
    _currentStroke = value;
    _badTriesThisStroke = 0;

    // Normalize the animation speed to the length of the stroke
    // The first stroke of 你 (length 520) is taken as reference
    if (currentStroke < nStrokes) {
      final currentMedian = medians[currentStroke];

      final medianPath = Path();
      if (currentMedian.length > 1) {
        medianPath.moveTo(
            currentMedian[0][0].toDouble(), currentMedian[0][1].toDouble());
        for (var point in currentMedian) {
          medianPath.lineTo(point[0].toDouble(), point[1].toDouble());
        }
      }

      final medianLength = medianPath.computeMetrics().first.length;

      if (medianLength > 0) {
        final normFactor = (medianLength / 520).clamp(0.5, 1.5);
        _setNormalizedStrokeAnimationSpeed(normFactor);
        _setNormalizedHintAnimationSpeed(normFactor);
      }
    }

    notifyListeners();
  }
}
