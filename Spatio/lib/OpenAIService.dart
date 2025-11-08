import 'dart:convert';

import 'package:dart_openai/openai.dart';
import 'package:dio/dio.dart';


class OpenAIService {
  final WolframAppID = "";

  Future<String> message(String key, String message,
      List<String> conversation) async {
    OpenAI.apiKey = key;
    try {
      String thought = await think(key, message, conversation);
      String wolfram = thought.split(" ").sublist(1).join(" ");
      print(wolfram);
      if (thought.contains("WolframX")) {
        final answer = await callWolfram(WolframAppID, wolfram);
        wolfram = "Here is Wolfram's result of the user's question: " + answer;
        OpenAIChatCompletionModel completion = await OpenAI.instance.chat.create(
            model: "gpt-3.5-turbo", messages: [
          OpenAIChatCompletionChoiceMessageModel(
              content: "You are an AI assistant, your objective today is reword Wolfram's answer by keeping in mind the user's lastest message.",
              role: OpenAIChatMessageRole.system
          ),
          OpenAIChatCompletionChoiceMessageModel(
              content: "Here is the user's lastest message: " + message,
              role: OpenAIChatMessageRole.system
          ),
          OpenAIChatCompletionChoiceMessageModel(
              content: "Here is the result that Wolfram gave you: " + wolfram,
              role: OpenAIChatMessageRole.system
          ),
        ]);
        return completion.choices[0].message.content;
      } else {
        wolfram =
        "You thought that the last answer wasn't a scientific question in need to use Wolfram, so you decided to use your own knowledge to answer the user";
      }
      OpenAIChatCompletionModel completion = await OpenAI.instance.chat.create(
          model: "gpt-3.5-turbo", messages: [
        const OpenAIChatCompletionChoiceMessageModel(
            content: "You are Spatio, an AI assistant designed to helped STEM students and researchers, you might use Wolfram to answer scientific questions. If the Wolfram result gives an error, tell the user that it didn't work and try to answer the question yourself.",
            role: OpenAIChatMessageRole.system
        ),
        OpenAIChatCompletionChoiceMessageModel(
            content: wolfram,
            role: OpenAIChatMessageRole.system
        ),
        OpenAIChatCompletionChoiceMessageModel(
            content: "Here is the past conversation with the user: " +
                jsonEncode(conversation),
            role: OpenAIChatMessageRole.system
        ),
        OpenAIChatCompletionChoiceMessageModel(
            content: message,
            role: OpenAIChatMessageRole.user
        )
      ]);
      return completion.choices[0].message.content;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> callWolfram(String key, String query) async {
    final apiUrl = 'http://api.wolframalpha.com/v1/result';
    final encodedQuery = Uri.encodeQueryComponent(query);
    final url = '$apiUrl?i=$encodedQuery&appid=$key';
    final response = await Dio().get(url);
    if (response.statusCode == 200) {
      print(url);
      return response.data;
    } else {
      throw Exception('The wolfram request did not work');
    }
  }

  Future<String> think(String key, String message,
      List<String> conversation) async {
    try {
      OpenAIChatCompletionModel thought = await OpenAI.instance.chat.create(
          model: "gpt-3.5-turbo", messages: [
        OpenAIChatCompletionChoiceMessageModel(
            content: "You are an AI assistant with the task to decode the message of the user and to verify if you need Wolfram to answer his question, keep in mind the user's conversation history."
                "There is a high probability that the user will ask a scientific question, if he asks a scientific question reply with 'WolframX', if not reply with 'AI'"
                "here is the message and remember, your answer MUST be one of these two words 'WolframX' or 'AI'"
                 ", here is the user's message: "+
                message,
            role: OpenAIChatMessageRole.system
        ),
      ]);
      print(thought.choices[0].message.content);
      return thought.choices[0].message.content + " " + message;
    } catch (e) {
      return e.toString();
    }
  }
}