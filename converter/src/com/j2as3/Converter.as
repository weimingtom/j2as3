package com.j2as3 {
	import flash.utils.Dictionary;

	internal class Converter {
		private var str:String;
		private var orginalStr:String;
		private var tokenizer:Tokenizer;
		private var inFNDef:Boolean, inConstructor:Boolean;
		private var cFNName:String,cFNType:String;
		private var post:String;
		private var isInnerClass:Boolean = false;
		private var posInnerClass:Array = new Array();
		private var packageImports:Dictionary = new Dictionary();
		public var classCount:int;
		public var lineCount:int;
		public var isJavaFile:Boolean;
		private var hasBeenAddedExclamationPoint:Boolean = false;

		public function Converter(str:String) {
			orginalStr = this.str = str;
			tokenizer = new Tokenizer(str);
			lineCount = classCount = 0;
			isJavaFile = false;
		}

		public function getNewClass():String {
			var tokens:Array = tokenizer.getAllTokens();
			var str:String = "";
			var orig:String = this.str;
			var temp:String;
			var lastPos:uint = 0;
			var newPos:uint;
			var used:Boolean;
			var t:Token;

			post = "";

			for (var i:int = 0; i < tokens.length; i++) {
				t = tokens[i];

				if (t.string == "import") {
					var imp:String = t.string + " " + tokens[i + 1].string + tokens[i + 2].string;
					var s:String = tokens[i + 1].string;
					var endPoint:int = s.lastIndexOf(".");
					var nameImpClass:String = s.substring(endPoint + 1, s.length);

					packageImports[nameImpClass] = imp;
				}
				used = false;
				if (i < tokens.length - 3) {
					if (isIdentifier(tokens[i]) &&
							tokens[i + 1].type == Token.STRING_LITERAL &&
							(tokens[i + 2].string == "=" || tokens[i + 2].string == ";" || tokens[i + 2].string == "," || tokens[i + 2] == ")")) {
						var varName:String = tokens[i + 1];
						var varType:String = toASType(tokens[i]);

						if (inFNDef || inConstructor || ((i > 0 && tokens[i - 1].string == 'const') || (i > 1 && tokens[i - 2].string == 'catch')))
							str += varName + ":" + varType;	// const str:String
						else
							str += "var " + varName + ":" + varType;

						i += 1;
						used = true;
					} else if (isIdentifier(tokens[i]) &&
							tokens[i + 1].type == Token.STRING_LITERAL &&
							tokens[i + 2] == "(") { //Function definition
						inFNDef = true;
						cFNName = tokens[i + 1];
						cFNType = toASType(tokens[i]);

						str += "function " + cFNName;
						used = true;
						i += 1;
					}
				}

				if (tokens[i] == "class" || tokens[i] == "interface") {
					if (isInnerClass) {

						if (post != "") {
							var closeBracketIndex:int = str.lastIndexOf("}");
							if (closeBracketIndex != -1) {
								str = str.substring(0, closeBracketIndex + 1) + post + str.substring(closeBracketIndex + 1, str.length + 1);
							}
							post = "";
						}
						var startPos:int = str.length - 1;
						posInnerClass.push(startPos);
					}

					if (i > 0 && tokens[i - 1].string != "public") {
						str += "\n" + "internal ";
					}
                       					
					isJavaFile = true;
					classCount++;
					isInnerClass = true;
				}

				if (i < tokens.length - 3) {	//Constructor definition
					if (isPPP(tokens[i]) && isIdentifier(tokens[i + 1]) && tokens[i + 2] == "(") {
						inConstructor = true;
						used = true;
						str += tokens[i] + " function " + tokens[i + 1];
						i++;
					}
				}

				if (i < tokens.length - 3) {
					if (tokens[i] == "package" && tokens[i + 1].type == Token.STRING_LITERAL && tokens[i + 2].string == ";") {
						str += tokens[i] + " " + tokens[i + 1] + " {\n";
						used = true;
						i += 2;
						post += "\n}";
					}
				}

				if (i < tokens.length - 3) {
					if (tokens[i] == "(" && isIdentifier(tokens[i + 1]) && tokens[i + 2] == ")") {
						if (tokens[i - 1].type != Token.STRING_LITERAL && (tokens[i - 1].string == "return" || tokens[i - 1].type != Token.KEYWORD)) {
							var castType:String = tokens[i + 1];
							i += 3;
							var n:String;
							var inside:uint = 0;
							var sss:String;
							var start:uint = i;
							sss = "";
							while (true) {
								n = tokens[i];
								if (n == "(" || n == "[" || n == "{") {
									inside++;
									sss += " " + n;
								}

								if (inside > 0) {
									if (n == ")" || n == "]" || n == "}") {
										if (inside > 0)
											inside--;
										sss += n;
									}
								} else {
									if (tokens[i].type == Token.SYMBOL && n != ".") {
										i--;
										break;
									}
								}
								i++;
							}
							sss = orig.substring(tokens[start].pos, tokens[i + 1].pos);
							str += castType + "(" + sss + ")";
							used = true;
						}
					}
				}

				if (i < tokens.length - 5) {
					if (isIdentifier(tokens[i]) &&
							tokens[i + 1] == "[" && tokens[i + 2] == "]" &&
							tokens[i + 3].type == Token.STRING_LITERAL &&
							(tokens[i + 4].string == "=" || tokens[i + 4].string == ";" || tokens[i + 4].string == "," || tokens[i + 4] == ")")) { //array
						varName = tokens[i + 3];
						varType = "Array";
						if (inFNDef || inConstructor)
							str += varName + ":" + varType;
						else
							str += "var " + varName + ":" + varType;
						i += 3;
						used = true;
					}
				}
				if (t.string == ")") {
					if (inFNDef) {
						inFNDef = false;
						used = true;
						str += "):" + cFNType + " ";
					} else if (inConstructor) {
						inConstructor = false;
					}
				}
				if (t.type == Token.NUMBER) { // clean it up
					str += cleanNumber(t.string);
					used = true;
				}
				if (t.type == Token.COMMENT) {
					//used = true
				}
				t = tokens[i];
				newPos = t.pos + t.string.length;
				if (i < tokens.length - 1)
					newPos = tokens[i + 1].pos;

				if (t.string == '@') { // && (tokens[i + 1] as Token).string == 'override'

					used = true;
					if (tokens[i + 1] == "Override") {
						str += '\r\n' + (tokens[i + 1] as Token).string.toLocaleLowerCase() + " ";

					} else {
						for (var key:String in packageImports) {
							if (key == tokens[i + 1].string) {

								str = str.replace(packageImports[key] + '\n', "");
							}
						}
					}
					if (tokens[i + 2] == '(') {
						while (tokens[i] != ')') {
							i++;
							if (i == tokens.length) {
								return null;
							}
						}
						i--;
					}

					i++;
					newPos = tokens[i + 1].pos;
				}
				var index:int = t.string.indexOf('equals');

				if ((index >= 0) && (index + 6 == t.string.length)) {
					if (index == 0) {
						str = str.substring(0, str.length - 1);
						str = removeExclamationPoint(str, true);
						str += " == ";
						used = true;
					} else {
						str = removeExclamationPoint(str, false);
						index = orig.indexOf('equals', t.pos);
						temp = orig.substring(t.pos, index - 1);//+ ' == ';
						if (hasBeenAddedExclamationPoint) {
							temp += ' != ';
							hasBeenAddedExclamationPoint = false;
						} else {
							temp += ' == ';
						}

						str += temp;
						used = true;
					}
				}

				if (!used) {
					if (str.indexOf('...', str.length - 4) != -1 && ((i > 5) && (tokens[i - 5].string == '(' || tokens[i - 5].string == ','))) {

						var indexOpeningBracket:int = str.lastIndexOf('(');
						var char1:int = str.indexOf(',', indexOpeningBracket);

						while (char1 != -1) {
							if (indexOpeningBracket < char1)
								indexOpeningBracket = char1;

							char1 = str.indexOf(',', char1 + 1);
						}


						str = str.substring(0, indexOpeningBracket + 1);
						str += " ... " + t.string;

					} else if (t.string == "throws") {
						i++;
						newPos = tokens[i + 1].pos;
					} else if (t.string == 'instanceof') {
						str += 'is ';
					}
					else if (t.string == 'final') {
						if (((tokens[i - 1] as Token).string == 'static') && ((tokens[i + 3] as Token).string == '=')) {
							str += 'const ';
							(tokens[i] as Token).string = "const";
						}
					}
					else {
						temp = orig.substring(lastPos, newPos);
						str += temp;
					}
				}
				lastPos = newPos;
			}
			if (isJavaFile) {
				var lines:Array = orginalStr.split("\n");
				lineCount = lines.length;
				if (lines[lineCount - 1].length == 0)
					lineCount--;
			}
			return addImportInnerClasses(str + post);
		}

		private function addImportInnerClasses(str:String):String {
			var code:String = str;
			if (posInnerClass.length > 0) {
				var index:int = str.lastIndexOf("}", posInnerClass[0]);
				if (index != -1) {
					code = "";
					posInnerClass.push(str.length - 1);
					var classCode:String = str.substring(0, index + 1);
					for (var i:int = 0; i < posInnerClass.length - 1; i++) {
						var beginIndex:int = str.lastIndexOf("}", posInnerClass[i]);
						var endIndex:int = str.lastIndexOf("}", posInnerClass[i + 1]);

						var innerclassCode:String = str.substring(beginIndex + 1, endIndex + 1);
						var imports:String = "\n\n";

						for (var key:String in packageImports) {
							if (innerclassCode.search(key) != -1) {
								imports += packageImports[key] + "\n"
							}
						}

						code += imports + innerclassCode;

					}
					code = classCode + code;

					while (code.search("\n\n\n") > -1)
						code = code.replace("\n\n\n", "\n\n");
				}
			}
			return code;
		}


		private function removeExclamationPoint(str:String, isSearchQuotes:Boolean):String {
			var indexOpeningBracket:int = str.lastIndexOf('(');

			var char1:int = str.indexOf('&', indexOpeningBracket);

			if (indexOpeningBracket < char1)
				indexOpeningBracket = char1;

			char1 = str.indexOf('|', indexOpeningBracket);

			if (indexOpeningBracket < char1)
				indexOpeningBracket = char1;

			var indexExclamationPoint:int = str.indexOf('!', indexOpeningBracket);
			var temp:String = '';
			if (indexExclamationPoint == -1) {
				temp = new String(str);
			} else if (isSearchQuotes) {
				if ((str.indexOf('"') != -1) && (str.indexOf('"') != str.lastIndexOf('"'))) {
					temp = str.substring(0, indexExclamationPoint);
					temp += str.substring(indexExclamationPoint + 1, str.length);
				} else {

				}
			} else {
				if (indexExclamationPoint == str.length - 1) {
					temp = str.substring(0, indexExclamationPoint);
					hasBeenAddedExclamationPoint = true;
				} else {
					temp = new String(str);
				}
			}
			return temp;
		}

		private function isIdentifier(token:Token):Boolean {
			return isPrimitiveType(token.string) || token.type == Token.STRING_LITERAL
		}

		private function isPrimitiveType(str:String):Boolean {
			return str == "int" || str == "byte" || str == "double" || str == "boolean" ||
					str == "float" || str == "void" || str == "char" || str == "short" || str == "long";
		}

		private function isPPP(str:String):Boolean {
			return str == "public" || str == "private" || str == "protected";
		}

		private function toASType(type:String):String {
			if (type == "double" || type == "float")
				return "Number";
			if (type == "Integer")
				return "int";
			if (type == "boolean")
				return "Boolean";
			if (type == "byte")
				return "uint";
			if (type == "long" || type == "short")
				return "Number";
			if (type == "char")
				return "String";
			return type;
		}

		private function cleanNumber(str:String):String {
			while (str.search("f") > -1)
				str = str.replace("f", "");
			return str;
		}
	}
}