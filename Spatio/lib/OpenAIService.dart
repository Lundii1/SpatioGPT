import 'dart:convert';

import 'package:dart_openai/openai.dart';


class OpenAIService {
  Future<String> message(String key, String message, List<String> conversation) async {
    OpenAI.apiKey = key;
    try
    {
      OpenAIChatCompletionModel completion = await OpenAI.instance.chat.create(model: "gpt-3.5-turbo", messages: [
        const OpenAIChatCompletionChoiceMessageModel(
            content: "You are an AI assistant on a mobile application",
            role: OpenAIChatMessageRole.system
        ),
        OpenAIChatCompletionChoiceMessageModel(
            content: "Here is the past conversation with the user: " + jsonEncode(conversation),
            role: OpenAIChatMessageRole.system
        ),
        OpenAIChatCompletionChoiceMessageModel(
            content: message,
            role: OpenAIChatMessageRole.user
        )
      ]);
      return completion.choices[0].message.content;
    } catch (e){
      return e.toString();
    }
  }
}
