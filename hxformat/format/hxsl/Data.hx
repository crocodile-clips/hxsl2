/*
 * format - haXe File Formats
 *
 * Copyright (c) 2008, The haXe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package format.hxsl;

import haxe.macro.Expr;

enum TexFlag {
	TMipMapDisable; // default
	TMipMapNearest;
	TMipMapLinear;
	TWrap;
	TClamp;	// default
	TFilterNearest;
	TFilterLinear; // default
	TSingle;
	TLodBias( v : Float );
}

enum TexParam {
	PMipMap;
	PWrap;
	PClamp;
	PFilter;
	PLodBias;
	PSingle;
}

enum Comp {
	X;
	Y;
	Z;
	W;
}

enum VarKind {
	VParam;
	VVar;
	VInput;
	VOut;
	VTmp;
	VTexture;
	// internal-usage only
	VCompileConstant;
	VGlobalTexture;
	VGlobalParam;
}

enum VarType {
	TBool;
	TFloat;
	TFloat2;
	TFloat3;
	TFloat4;
	TInt;
	TMatrix( r : Int, c : Int, transpose : { t : Null<Bool> } );
	TTexture( cube : Bool );
	TArray( t : VarType, size : Int );
}

typedef Variable = {
	var name : String;
	var type : VarType;
	var kind : VarKind;
	var index : Int;
	var pos : Position;
	// internal-usage only
	var kindInferred : Bool;
	var uid : Int;
	var refuid : Int;
	var read : Bool;
	var write : Int;
	var assign : { v : Variable, s : Array<Comp> };
}

enum CodeOp {
	CAdd;
	CSub;
	CMul;
	CDiv;
	CMin;
	CMax;
	CPow;
	CCross;
	CDot;
	CLt;
	CGte;
	CMod;
	CEq;
	CNeq;
	// Internal usage only
	CAnd;
	COr;
}

enum CodeUnop {
	CRcp;
	CSqrt;
	CRsq;
	CLog;
	CExp;
	CLen;
	CSin;
	CCos;
	CAbs;
	CNeg;
	CSat;
	CFrac;
	CInt;
	CNorm;
	CKill;
	CTrans;
	// Internal usage only
	CNot;
}

// final hxsl

enum CodeValueDecl {
	CVar( v : Variable, ?swiz : Array<Comp> );
	COp( op : CodeOp, e1 : CodeValue, e2 : CodeValue );
	CUnop( op : CodeUnop, e : CodeValue );
	CAccess( v : Variable, idx : CodeValue );
	CTex( v : Variable, acc : CodeValue, flags : Array<TexFlag> );
	CSwiz( e : CodeValue, swiz : Array<Comp> );
	CBlock( exprs : Array<{ v : CodeValue, e : CodeValue }>, v : CodeValue );
	// used in intermediate representation only
	CIf( cond : CodeValue, eif : Array<{v:CodeValue, e:CodeValue}>, eelse : Null<Array<{v:CodeValue, e:CodeValue}>> );
	CLiteral( value : Array<Float> );
	CFor( iterator : Variable, start : CodeValue, end : CodeValue, exprs : Array<{v:CodeValue, e:CodeValue}> );
	CTexE( v : Variable, acc : CodeValue, flags : Array<{t:TexParam, e:CodeValue}> );
	CVector( vals : Array<CodeValue> );
}

typedef CodeValue = {
	var d : CodeValueDecl;
	var t : VarType;
	var p : Position;
}

typedef Code = {
	var vertex : Bool;
	var pos : Position;
	var args : Array<Variable>;
	var consts : Array<Array<Float>>;
	var tex : Array<Variable>;
	var exprs : Array<{ v : Null<CodeValue>, e : CodeValue }>;
	var tempSize : Int;
}

typedef Data = {
	var vertex : Code;
	var fragment : Code;
	var input : Array<Variable>;
	var compileVars : Map<String, Variable>;
}

// parsed hxsl

enum ParsedValueDecl {
	PVar( v : String );
	PConst( v : String );
	PLocal( v : ParsedVar );
	POp( op : CodeOp, e1 : ParsedValue, e2 : ParsedValue );
	PUnop( op : CodeUnop, e : ParsedValue );
	PTex( v : String, acc : ParsedValue, flags : Array<ParsedExpr> );
	PSwiz( e : ParsedValue, swiz : Array<Comp> );
	PIf( cond : ParsedValue, eif : Array<ParsedExpr>, eelse : Array<ParsedExpr> );
	PFor( it : ParsedVar, first : ParsedValue, last : ParsedValue, expr:ParsedExpr );
	PIff( cond : ParsedValue, eif : ParsedValue, eelse : ParsedValue ); // inline if statement
	PVector( el : Array<ParsedValue> );
	PRow( e : ParsedValue, index : Int );
	PBlock( el : Array<ParsedExpr> );
	PReturn( e : ParsedValue );
	PCall( n : String, vl : Array<ParsedValue> );
	PAccess( v : String, e : ParsedValue );
}

typedef ParsedValue = {
	var v : ParsedValueDecl;
	var p : Position;
}

typedef ParsedVar = {
	var n : String;
	var t : VarType;
	var k : VarKind;
	var p : Position;
}

typedef ParsedExpr = {
	var v : Null<ParsedValue>;
	var e : ParsedValue;
	var p : Position;
}

typedef ParsedCode = {
	var pos : Position;
	var args : Array<ParsedVar>;
	var exprs : Array<ParsedExpr>;
}

typedef ParsedHxsl = {
	var pos : Position;
	var vars : Array<ParsedVar>;
	var vertex : ParsedCode;
	var fragment : ParsedCode;
	var helpers : Map<String, ParsedCode>;
}

typedef Error = haxe.macro.Expr.Error;

class Tools {
	public static function swizBits( s : Array<Comp>, t : VarType ) {
		if( s == null ) return fullBits(t);
		var b = 0;
		for( x in s )
			b |= 1 << Type.enumIndex(x);
		return b;
	}

	public static function fullBits( t : VarType ) {
		return (1 << Tools.floatSize(t)) - 1;
	}

	public static function isFloat( t : VarType ) {
		return switch( t ) {
		case TFloat, TFloat2, TFloat3, TFloat4, TInt: true;
		default: false;
		};
	}

	public static function regSize( t : VarType ) {
		return switch( t ) {
		case TMatrix(w, h, t): t.t ? h : w;
		case TArray(t, size):
			var v = regSize(t);
			switch(t) {
			case TMatrix(_, _, _): if ( v < 4 ) v = 4;
			default:
			}
			v * size;
		default: 1;
		}
	}

	public static function floatSize( t : VarType ) {
		return switch( t ) {
		case TBool: 1;
		case TFloat: 1;
		case TFloat2: 2;
		case TFloat3: 3;
		case TFloat4, TInt: 4;
		case TTexture(_): 0;
		case TMatrix(w, h, _): w * h;
		case TArray(t, count):
			var size = floatSize(t);
			if( size < 4 ) size = 4;
			size * count;
		}
	}

	public static function makeFloat( i : Int ) {
		return switch( i ) {
			case 1: TFloat;
			case 2: TFloat2;
			case 3: TFloat3;
			case 4: TFloat4;
			default: throw "assert";
		};
	}

}
