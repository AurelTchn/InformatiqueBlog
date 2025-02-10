import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  final String content;
  final int initialMaxLines;
  final int incrementLines;

  const ExpandableText({
    Key? key,
    required this.content,
    this.initialMaxLines = 10,
    this.incrementLines = 10,
  }) : super(key: key);

  @override
  _ExpandableTextState createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  late int currentMaxLines;
  late bool isFullyExpanded;

  @override
  void initState() {
    super.initState();
    currentMaxLines = widget.initialMaxLines;
    isFullyExpanded = false;
  }

  void toggleExpand() {
    setState(() {
      if (currentMaxLines < widget.content.length ~/ 50) {
        // Ajoute progressivement des lignes tant qu'il y a du contenu
        currentMaxLines += widget.incrementLines;
      } else {
        // Quand tout est affiché, on cache le bouton
        isFullyExpanded = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.content,
            textAlign: TextAlign.justify,
            maxLines: isFullyExpanded ? null : currentMaxLines,
            overflow: isFullyExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        if (!isFullyExpanded)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: toggleExpand,
              child: const Text("Voir plus"),
            ),
          ),
      ],
    );
  }
}
