/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFApi

import Absyn;
import AbsynUtil;
import SCode;
import DAE;

protected

import Inst = NFInst;
import Builtin = NFBuiltin;
import NFBinding.Binding;
import NFComponent.Component;
import ComponentRef = NFComponentRef;
import Dimension = NFDimension;
import Expression = NFExpression;
import NFClass.Class;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import NFModifier.Modifier;
import NFModifier.ModifierScope;
import Operator = NFOperator;
import Equation = NFEquation;
import Statement = NFStatement;
import NFType.Type;
import Subscript = NFSubscript;
import Connector = NFConnector;
import Connection = NFConnection;
import Algorithm = NFAlgorithm;
import ExpOrigin = NFTyping.ExpOrigin;


import Array;
import Config;
import Error;
import FBuiltin;
import Flags;
import Flatten = NFFlatten;
import Global;
import InstUtil = NFInstUtil;
import List;
import Lookup = NFLookup;
import MetaModelica.Dangerous;
import Typing = NFTyping;
import ExecStat.{execStat,execStatReset};
import SCodeDump;
import SCodeUtil;
import System;
import NFCall.Call;
import Absyn.Path;
import NFClassTree.ClassTree;
import NFSections.Sections;
import NFInstNode.CachedData;
import NFInstNode.NodeTree;
import StringUtil;
import UnitCheck = NFUnitCheck;
import NFPrefixes.*;
import Prefixes = NFPrefixes;
import NFFlatten.FunctionTree;
import ConvertDAE = NFConvertDAE;
import Scalarize = NFScalarize;
import Restriction = NFRestriction;
import ComplexType = NFComplexType;
import Package = NFPackage;
import NFFunction.Function;
import FlatModel = NFFlatModel;
import ElementSource;
import SimplifyModel = NFSimplifyModel;
import SimplifyExp = NFSimplifyExp;
import Record = NFRecord;
import Variable = NFVariable;
import OperatorOverloading = NFOperatorOverloading;
import EvalConstants = NFEvalConstants;
import VerifyModel = NFVerifyModel;
import Interactive;
import NFInst;
import DAEUtil;
import ComponentReference;
import NFCeval;
import Util;

public
function evaluateAnnotation
  "Instantiates the annotation class, gets the DAE and populates the annotation result"
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  input Absyn.Annotation inAnnotation;
  output String outString = "";
protected
  Boolean b;
algorithm
  b := Flags.set(Flags.SCODE_INST, true);
  try
    outString := evaluateAnnotation_dispatch(absynProgram, classPath, inAnnotation);
    Flags.set(Flags.SCODE_INST, b);
  else
    Flags.set(Flags.SCODE_INST, b);
    fail();
  end try;
end evaluateAnnotation;

protected
function evaluateAnnotation_dispatch
  "Instantiates the annotation class, gets the DAE and populates the annotation result"
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  input Absyn.Annotation inAnnotation;
  output String outString = "";
protected
  InstNode top, cls, inst_cls, anncls, inst_anncls;
  String name, clsName, annName, str;
  FlatModel flat_model;
  FunctionTree funcs;
  SCode.Program program;
  DAE.FunctionTree daeFuncs;
  Absyn.Path fullClassPath;
  list<Absyn.ElementArg> el = {};
  list<String> stringLst = {};
  Absyn.Exp absynExp;
  Expression exp;
  DAE.Exp dexp;
  list<Absyn.ComponentItem> items;
  Option<Absyn.ConstrainClass> cc;
  SourceInfo info;
  list<Absyn.ElementArg> mod, stripped_mod, graphics_mod;
  Absyn.EqMod eqmod;
  SCode.Mod smod;
  DAE.DAElist dae;
  Type ty;
  Variability var;
algorithm
  stringLst := {};

  Absyn.ANNOTATION(el) := inAnnotation;

  for e in listReverse(el) loop
    str := matchcontinue e
      case Absyn.MODIFICATION(
          path = Absyn.IDENT(annName),
          modification = SOME(Absyn.CLASSMOD({}, eqmod as Absyn.EQMOD(absynExp))),
          info = info)
        algorithm
          // no need for the class if there are no crefs
          if AbsynUtil.onlyLiteralsInEqMod(eqmod) then
            (program, top) := mkTop(absynProgram);
            inst_cls := top;
          else
            // run the front-end front
            (program, name, top, inst_cls) := frontEndFront(absynProgram, classPath);
          end if;

          exp := NFInst.instExp(absynExp, inst_cls, info);
          (exp, ty, var) := Typing.typeExp(exp, ExpOrigin.CLASS, info);
          // exp := NFCeval.evalExp(exp);
          exp := SimplifyExp.simplify(exp);
          str := Expression.toString(exp);
        then
          stringAppendList({annName, "=", str});

      case Absyn.MODIFICATION(
          path = Absyn.IDENT(annName),
          modification = SOME(Absyn.CLASSMOD(mod, Absyn.NOMOD())),
          info = info)
        algorithm
          // no need for the class if there are no crefs
          if AbsynUtil.onlyLiteralsInAnnotationMod(mod) then
            (program, top) := mkTop(absynProgram);
            inst_cls := top;
          else
            // run the front-end front
            (program, name, top, inst_cls) := frontEndFront(absynProgram, classPath);
          end if;

          (stripped_mod, graphics_mod) := AbsynUtil.stripGraphicsAndInteractionModification(mod);

          smod := SCodeUtil.translateMod(SOME(Absyn.CLASSMOD(stripped_mod, Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), info);
          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, AbsynUtil.dummyInfo, checkAccessViolations = false);
          inst_anncls := NFInst.expand(anncls);
          inst_anncls := NFInst.instClass(inst_anncls, Modifier.create(smod, annName, ModifierScope.CLASS(annName), {inst_cls, inst_anncls}, inst_cls), NFComponent.DEFAULT_ATTR, true, 0, inst_cls);

          execStat("NFApi.instantiate("+ annName + SCodeDump.printModStr(smod) + ")");

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls);
          execStat("NFApi.instExpressions("+ annName + SCodeDump.printModStr(smod) + ")");

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM));
          execStat("NFApi.updateImplicitVariability");

          dae := frontEndBack(inst_anncls, annName);
          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));

          if (stringEq(annName, "Icon") or stringEq(annName, "Diagram")) and not listEmpty(graphics_mod) then
            try
              {Absyn.MODIFICATION(modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp = absynExp))))} := graphics_mod;
              exp := NFInst.instExp(absynExp, inst_cls, info);
              (exp, ty, var) := Typing.typeExp(exp, ExpOrigin.CLASS, info);
              // exp := NFCeval.evalExp(exp);
              exp := SimplifyExp.simplify(exp);
              str := str + ", " + Expression.toString(exp);
            else
              // just don't fail!
            end try;
          end if;
        then
          str;

      case Absyn.MODIFICATION(path = Absyn.IDENT(annName), modification = NONE(), info = info)
        algorithm
          (program, top) := mkTop(absynProgram);
          inst_cls := top;

          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, AbsynUtil.dummyInfo, checkAccessViolations = false);

          inst_anncls := NFInst.instantiate(anncls);

          execStat("NFApi.instantiate("+ annName +")");

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls);
          execStat("NFApi.instExpressions("+ annName +")");

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM));
          execStat("NFApi.updateImplicitVariability");

          dae := frontEndBack(inst_anncls, annName);
          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        then
          str;

    end matchcontinue;

    stringLst := str :: stringLst;
  end for;

  outString := stringDelimitList(stringLst, ", ");

end evaluateAnnotation_dispatch;

public
function evaluateAnnotations
  "Instantiates the annotation class, gets the DAE and populates the annotation result"
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  input list<Absyn.Element> inElements;
  output list<String> outStringLst = {};
protected
  Boolean b;
algorithm
  b := Flags.set(Flags.SCODE_INST, true);
  try
    outStringLst := evaluateAnnotations_dispatch(absynProgram, classPath, inElements);
    Flags.set(Flags.SCODE_INST, b);
  else
    Flags.set(Flags.SCODE_INST, b);
    fail();
  end try;
end evaluateAnnotations;

protected
function evaluateAnnotations_dispatch
  "Instantiates the annotation class, gets the DAE and populates the annotation result"
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  input list<Absyn.Element> inElements;
  output list<String> outStringLst = {};
protected
  InstNode top, cls, inst_cls, anncls, inst_anncls;
  String name, clsName, annName, str;
  FlatModel flat_model;
  FunctionTree funcs;
  SCode.Program program;
  DAE.FunctionTree daeFuncs;
  Absyn.Path fullClassPath;
  list<list<Absyn.ElementArg>> elArgs = {}, el = {};
  list<String> stringLst = {};
  Absyn.Exp absynExp;
  Expression exp;
  DAE.Exp dexp;
  list<Absyn.ComponentItem> items;
  Option<Absyn.ConstrainClass> cc;
  SourceInfo info;
  list<Absyn.ElementArg> mod;
  Absyn.EqMod eqmod;
  SCode.Mod smod;
  DAE.DAElist dae;
  Type ty;
  Variability var;
algorithm
  // handle the annotations
  for i in inElements loop
   elArgs := matchcontinue i
      case Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = items), constrainClass = cc)
        algorithm
          el := AbsynUtil.getAnnotationsFromItems(items, AbsynUtil.getAnnotationsFromConstraintClass(cc));
        then
          listAppend(el, elArgs);

      case Absyn.ELEMENT(specification = Absyn.COMPONENTS())
        then {}::elArgs;

      else elArgs;
    end matchcontinue;
  end for;

  for l in elArgs loop

  stringLst := {};

  for e in listReverse(l) loop
    str := matchcontinue e
      case Absyn.MODIFICATION(
          path = Absyn.IDENT(annName),
          modification = SOME(Absyn.CLASSMOD({}, eqmod as Absyn.EQMOD(absynExp))),
          info = info)
        algorithm
          // no need for the class if there are no crefs
          if AbsynUtil.onlyLiteralsInEqMod(eqmod) then
            (program, top) := mkTop(absynProgram);
            inst_cls := top;
          else
            // run the front-end front
            (program, name, top, inst_cls) := frontEndFront(absynProgram, classPath);
          end if;

          exp := NFInst.instExp(absynExp, inst_cls, info);
          (exp, ty, var) := Typing.typeExp(exp, ExpOrigin.CLASS, info);
          // exp := NFCeval.evalExp(exp);
          exp := SimplifyExp.simplify(exp);
          str := Expression.toString(exp);
        then
          stringAppendList({annName, "=", str});

      case Absyn.MODIFICATION(
          path = Absyn.IDENT(annName),
          modification = SOME(Absyn.CLASSMOD(mod, Absyn.NOMOD())),
          info = info)
        algorithm
          // no need for the class if there are no crefs
          if AbsynUtil.onlyLiteralsInAnnotationMod(mod) then
            (program, top) := mkTop(absynProgram);
            inst_cls := top;
          else
            // run the front-end front
            (program, name, top, inst_cls) := frontEndFront(absynProgram, classPath);
          end if;

          smod := SCodeUtil.translateMod(SOME(Absyn.CLASSMOD(mod, Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), info);
          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, AbsynUtil.dummyInfo, checkAccessViolations = false);
          inst_anncls := NFInst.expand(anncls);
          inst_anncls := NFInst.instClass(inst_anncls, Modifier.create(smod, annName, ModifierScope.CLASS(annName), {inst_cls, inst_anncls}, inst_cls), NFComponent.DEFAULT_ATTR, true, 0, inst_cls);

          execStat("NFApi.instantiate("+ annName + SCodeDump.printModStr(smod) + ")");

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls);
          execStat("NFApi.instExpressions("+ annName + SCodeDump.printModStr(smod) + ")");

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM));
          execStat("NFApi.updateImplicitVariability");

          dae := frontEndBack(inst_anncls, annName);
          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        then
          stringAppendList({annName, "(", str, ")"});

      case Absyn.MODIFICATION(
          path = Absyn.IDENT(annName),
          modification = SOME(Absyn.CLASSMOD(_, Absyn.NOMOD())))
        then stringAppendList({annName, "(error)"});

      case Absyn.MODIFICATION(path = Absyn.IDENT(annName), modification = NONE(), info = info)
        algorithm
          (program, top) := mkTop(absynProgram);
          inst_cls := top;

          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, AbsynUtil.dummyInfo, checkAccessViolations = false);

          inst_anncls := NFInst.instantiate(anncls);

          execStat("NFApi.instantiate("+ annName +")");

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls);
          execStat("NFApi.instExpressions("+ annName +")");

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM));
          execStat("NFApi.updateImplicitVariability");

          dae := frontEndBack(inst_anncls, annName);
          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        then
          stringAppendList({annName, "(", str, ")"});

    end matchcontinue;

    stringLst := str :: stringLst;
  end for;

  str := stringDelimitList(stringLst, ", ");
  outStringLst := stringAppendList({"{", str, "}"}) :: outStringLst;

  end for;

end evaluateAnnotations_dispatch;

public
function mkFullyQual
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  input Absyn.Path pathToQualify;
  output Absyn.Path qualPath;
protected
  InstNode top, inst_cls, cls;
  SCode.Program program;
  String name;
  Boolean b;
algorithm
  b := Flags.set(Flags.SCODE_INST, true);
  try
    // run the front-end front
    (program, name, top, inst_cls) := frontEndFront(absynProgram, classPath);
    cls := Lookup.lookupClassName(pathToQualify, inst_cls, AbsynUtil.dummyInfo, checkAccessViolations = false);
    qualPath := InstNode.scopePath(cls, true);
    Flags.set(Flags.SCODE_INST, b);
  else
    // do not fail, just return the Absyn path
    qualPath := pathToQualify;
    Flags.set(Flags.SCODE_INST, b);
  end try;
end mkFullyQual;

protected
function frontEndFront
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  output SCode.Program program;
  output String name;
  output InstNode top;
  output InstNode inst_cls;
protected
  list<tuple<tuple<Absyn.Program, Absyn.Path>, tuple<SCode.Program, String, InstNode, InstNode>>> cache;
algorithm
  cache := getGlobalRoot(Global.instNFInstCacheIndex);
  if not listEmpty(cache) then
    for i in cache loop
      if AbsynUtil.pathEqual(classPath, Util.tuple22(Util.tuple21(i))) then
        if referenceEq(absynProgram, Util.tuple21(Util.tuple21(i))) then
          (program, name, top, inst_cls) := Util.tuple22(i);
          return;
        end if;
        // program changed, wipe the cache!
        cache := {};
        break;
      end if;
    end for;
  end if;
  (program, name, top, inst_cls) := frontEndFront_dispatch(absynProgram, classPath);
  if listLength(cache) > 100 then
    // trim it down, keep 10
	  cache := List.firstN(cache, 10);
  end if;

  cache := ((absynProgram,classPath),(program, name, top, inst_cls))::cache;
  setGlobalRoot(Global.instNFInstCacheIndex, cache);
end frontEndFront;

protected
function mkTop
  input Absyn.Program absynProgram;
  output SCode.Program program;
  output InstNode top;
protected
  SCode.Program scode_builtin, graphicProgramSCode;
  Absyn.Program placementProgram;
  InstNode cls;
  list<tuple<Absyn.Program, tuple<SCode.Program, InstNode>>> cache;
  Boolean update = true;
algorithm
  cache := getGlobalRoot(Global.instNFNodeCacheIndex);
  if not listEmpty(cache) then
    // if absyn is the same, all fine, reuse
    if referenceEq(absynProgram, Util.tuple21(listHead(cache))) then
      (program, top) := Util.tuple22(listHead(cache));
      update := false;
    else
      update := true;
    end if;
  end if;

  if update then
    (_, scode_builtin) := FBuiltin.getInitialFunctions();
    program := SCodeUtil.translateAbsyn2SCode(absynProgram);
    program := listAppend(scode_builtin, program);
    placementProgram := Interactive.modelicaAnnotationProgram(Config.getAnnotationVersion());
    graphicProgramSCode := SCodeUtil.translateAbsyn2SCode(placementProgram);
    program := listAppend(program, graphicProgramSCode);

    // gather here all the flags to disable expansion
    // and scalarization if -d=-nfScalarize is on
    if not Flags.isSet(Flags.NF_SCALARIZE) then
      // make sure we don't expand anything
      Flags.set(Flags.NF_EXPAND_OPERATIONS, false);
      Flags.set(Flags.NF_EXPAND_FUNC_ARGS, false);
    end if;

    System.setUsesCardinality(false);

    // Create a root node from the given top-level classes.
    top := NFInst.makeTopNode(program);

    cache := {(absynProgram, (program, top))};
    setGlobalRoot(Global.instNFNodeCacheIndex, cache);
  end if;
end mkTop;

protected
function frontEndFront_dispatch
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  output SCode.Program program;
  output String name;
  output InstNode top;
  output InstNode inst_cls;
protected
  SCode.Program scode_builtin, graphicProgramSCode;
  Absyn.Program placementProgram;
  InstNode cls;
  list<tuple<Absyn.Program, tuple<SCode.Program, InstNode>>> cache;
  Boolean update = true;
algorithm
  (program, top) := mkTop(absynProgram);

  name := AbsynUtil.pathString(classPath);
  execStat("NFApi.mkTop("+ name +")");

  // Look up the class to instantiate and mark it as the root class.
  cls := Lookup.lookupClassName(classPath, top, AbsynUtil.dummyInfo, checkAccessViolations = false);
  execStat("NFApi.lookup("+ name +")");
  cls := InstNode.setNodeType(InstNodeType.ROOT_CLASS(InstNode.EMPTY_NODE()), cls);

  // Initialize the storage for automatically generated inner elements.
  top := InstNode.setInnerOuterCache(top, CachedData.TOP_SCOPE(NodeTree.new(), cls));

  // Instantiate the class.
  inst_cls := NFInst.instantiate(cls);
  NFInst.insertGeneratedInners(inst_cls, top);
  execStat("NFApi.instantiate("+ name +")");

  // Instantiate expressions (i.e. anything that can contains crefs, like
  // bindings, dimensions, etc). This is done as a separate step after
  // instantiation to make sure that lookup is able to find the correct nodes.
  NFInst.instExpressions(inst_cls);
  execStat("NFApi.instExpressions("+ name +")");

  // Mark structural parameters.
  NFInst.updateImplicitVariability(inst_cls, Flags.isSet(Flags.EVAL_PARAM));
  execStat("NFApi.updateImplicitVariability");
end frontEndFront_dispatch;

protected
function frontEndBack
  input InstNode inst_cls;
  input String name;
  output DAE.DAElist dae;
protected
  InstNode top;
  String clsName, annName, str;
  FlatModel flat_model;
  FunctionTree funcs;
  SCode.Program scode_builtin, program, graphicProgramSCode;
  SCode.Element scls, sAnnCls;
  Absyn.Program placementProgram;
  DAE.FunctionTree daeFuncs;
  Absyn.Path fullClassPath;
  list<list<Absyn.ElementArg>> elArgs, el = {};
  list<String> stringLst = {};
  Absyn.Exp absynExp;
  Expression exp;
  DAE.Exp dexp;
  list<Absyn.ComponentItem> items;
  Option<Absyn.ConstrainClass> cc;
  SourceInfo info;
  list<Absyn.ElementArg> mod;
  SCode.Mod smod;
algorithm
  // Type the class.
  Typing.typeClass(inst_cls, name);

  // Flatten and simplify the model.
  flat_model := Flatten.flatten(inst_cls, name);
  flat_model := EvalConstants.evaluate(flat_model);
  flat_model := SimplifyModel.simplify(flat_model);
  funcs := Flatten.collectFunctions(flat_model, name);

  // Collect package constants that couldn't be substituted with their values
  // (e.g. because they where used with non-constant subscripts), and add them
  // to the model.
  flat_model := Package.collectConstants(flat_model, funcs);

  // Scalarize array components in the flat model.
  if Flags.isSet(Flags.NF_SCALARIZE) then
    flat_model := Scalarize.scalarize(flat_model, name);
  else
    // Remove empty arrays from variables
    flat_model.variables := List.filterOnFalse(flat_model.variables, Variable.isEmptyArray);
  end if;

  VerifyModel.verify(flat_model);

  // Convert the flat model to a DAE.
  (dae, daeFuncs) := ConvertDAE.convert(flat_model, funcs, name, InstNode.info(inst_cls));

  // Do unit checking
  UnitCheck.checkUnits(dae, daeFuncs);
end frontEndBack;

  annotation(__OpenModelica_Interface="backend");
end NFApi;
