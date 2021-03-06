/********************************************************************************
 * Copyright (c) 2011-2017 Red Hat Inc. and/or its affiliates and others
 *
 * This program and the accompanying materials are made available under the 
 * terms of the Apache License, Version 2.0 which is available at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * SPDX-License-Identifier: Apache-2.0 
 ********************************************************************************/
package org.eclipse.ceylon.compiler.js;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.eclipse.ceylon.common.Backend;
import org.eclipse.ceylon.compiler.typechecker.tree.Tree;
import org.eclipse.ceylon.model.typechecker.model.Declaration;
import org.eclipse.ceylon.model.typechecker.model.Value;

import org.eclipse.ceylon.compiler.js.util.JsIdentifierNames;
import org.eclipse.ceylon.compiler.js.util.RetainedVars;
import org.eclipse.ceylon.compiler.js.util.TypeUtils;

/** This component is used by the main JS visitor to generate code for comprehensions.
 * 
 * @author Enrique Zamudio
 * @author Ivo Kasiuk
 */
class ComprehensionGenerator {

    private final GenerateJsVisitor gen;
    private final JsIdentifierNames names;
    private final RetainedVars retainedVars = new RetainedVars();
    private final String finished;
    private final Set<Declaration> directAccess;

    ComprehensionGenerator(GenerateJsVisitor gen, JsIdentifierNames names, Set<Declaration> directDeclarations) {
        this.gen = gen;
        finished = String.format("%sfinished()", gen.getClAlias());
        this.names = names;
        directAccess = directDeclarations;
    }

    private void expressionClause(final Tree.ExpressionComprehensionClause startClause,
            final int initialIfClauses, final String tail, final Tree.Comprehension that) {
        // record exhaustion state: return a function that
        // * on first call, returns the expression,
        // * on subsequent calls, returns finished.
        String exhaustionVarName = names.createTempVariable();
        gen.out("var ", exhaustionVarName, "=false");
        gen.endLine(true);
        gen.out("return function()");
        gen.beginBlock();
        gen.out("if(", exhaustionVarName, ") return ", finished);
        gen.endLine(true);
        gen.out(exhaustionVarName, "=true");
        gen.endLine(true);
        gen.out("return ");
        final Tree.Expression _expr = startClause.getExpression();
        if (!gen.isNaturalLiteral(_expr.getTerm())) {
            _expr.visit(gen);
        }
        gen.endBlockNewLine(true);
        for (int i = 0; i < initialIfClauses; i++) {
            gen.endBlock();
        }
        gen.endLine();
        gen.out(tail);
        gen.endBlock(); // end one more block - this one is for the function
        gen.out(",");
        TypeUtils.printTypeArguments(that,
                TypeUtils.wrapAsIterableArguments(that.getTypeModel()), gen, false, null);
        gen.out(")");
    }

    private Tree.Expression gatherLoopsAndVariables(Tree.ForComprehensionClause forClause,
            final Tree.Comprehension that, final List<ComprehensionLoopInfo> loops) {
        Tree.Expression expression = null;
        while (forClause != null) {
            final ComprehensionLoopInfo loop = new ComprehensionLoopInfo(that, forClause.getForIterator());
            Tree.ComprehensionClause clause = forClause.getComprehensionClause();
            while ((clause != null) && !(clause instanceof Tree.ForComprehensionClause)) {
                if (clause instanceof Tree.IfComprehensionClause) {
                    Tree.IfComprehensionClause ifClause = (Tree.IfComprehensionClause) clause;
                    loop.conditions.add(ifClause.getConditionList());
                    loop.conditionVars.add(gen.conds.gatherVariables(ifClause.getConditionList(), true, false));
                    clause = ifClause.getComprehensionClause();

                } else if (clause instanceof Tree.ExpressionComprehensionClause) {
                    expression = ((Tree.ExpressionComprehensionClause) clause).getExpression();
                    clause = null;
                } else {
                    that.addError("No support for comprehension clause of type "
                                  + clause.getClass().getName(), Backend.JavaScript);
                    return expression;
                }
            }
            loops.add(loop);
            forClause = (Tree.ForComprehensionClause) clause;
        }
        return expression;
    }

    void generateComprehension(final Tree.Comprehension that) {
        gen.out(gen.getClAlias(), "for$(function()");
        gen.beginBlock();
        if (gen.opts.isComment()) {
            gen.out("//Comprehension"); gen.location(that); gen.endLine();
        }

        // gather information about all loops and conditions in the comprehension
        List<ComprehensionLoopInfo> loops = new ArrayList<ComprehensionLoopInfo>();
        Tree.Expression expression = null;
        Tree.ComprehensionClause startClause = that.getInitialComprehensionClause();
        String tail = null;
        /**
         * The number of initial "if" comprehension clauses, i.&nbsp;e., the number of blocks that have to be ended.
         */
        int initialIfClauses = 0;
        while (!(startClause instanceof Tree.ForComprehensionClause)) {
            if (startClause instanceof Tree.IfComprehensionClause) {
                // check the condition
                Tree.IfComprehensionClause ifClause = (Tree.IfComprehensionClause)startClause;
                gen.conds.specialConditions(
                        gen.conds.gatherVariables(ifClause.getConditionList(), true, false),
                        ifClause.getConditionList(),
                        "if", false);
                initialIfClauses++;
                gen.beginBlock();
                startClause = ifClause.getComprehensionClause();
                if (!(startClause instanceof Tree.IfComprehensionClause)) {
                    // we'll put the rest of the comprehension inside this if block;
                    // outside the if block, return nothing (if any condition isn't true)
                    tail = "return function(){return " + finished + ";}";
                }
            } else if (startClause instanceof Tree.ExpressionComprehensionClause) {
                expressionClause((Tree.ExpressionComprehensionClause)startClause, initialIfClauses, tail, that);
                return;
            } else {
                that.addError("No support for comprehension clause of type "
                              + startClause.getClass().getName(), Backend.JavaScript);
                return;
            }
        }
        expression = gatherLoopsAndVariables((Tree.ForComprehensionClause)startClause, that, loops);

        // generate variables and "next" function for each for loop
        for (int loopIndex=0; loopIndex<loops.size(); loopIndex++) {
            ComprehensionLoopInfo loop = loops.get(loopIndex);

            // iterator variable
            gen.out("var ", loop.itVarName, "=");
            if (loopIndex == 0) {
                loop.forIterator.getSpecifierExpression().visit(gen);
                gen.out(".iterator()");
            } else {
                gen.out(gen.getClAlias(), "emptyIterator()");
            }

            // value or key/value variables
            gen.out(",", loop.valueVarName, "=", finished);
            if (loop.pattern != null) {
                HashSet<Declaration> decs = new HashSet<>();
                new Destructurer(loop.pattern, null, decs, "", true, false);
                for (Declaration d : decs) {
                    gen.out(",", names.name(d));
                }
            }
            gen.endLine(true);

            // generate the "next" function for this loop
            boolean isLastLoop = (loopIndex == (loops.size()-1));
            if (isLastLoop && loop.conditions.isEmpty() && (loop.pattern == null)) {
                // simple case: innermost loop without conditions, no key/value iterator
                gen.out("var n", loop.valueVarName, "=function(){return ",
                        loop.valueVarName, "=", loop.itVarName, ".next();}");
                gen.endLine();
            }
            else {
                gen.out("var n", loop.valueVarName, "=function()");
                gen.beginBlock();

                String elemVarName = loop.valueVarName;

                // if/while ((elemVar=it.next()!==$finished)
                gen.out(loop.conditions.isEmpty()?"if":"while", "((", elemVarName, "=",
                        loop.itVarName, ".next())!==", finished, ")");
                gen.beginBlock();

                if (loop.pattern != null) {
                    //deconstruct here
                    new Destructurer(loop.pattern, gen, directAccess, elemVarName, true, false);
                    gen.endLine(true);
                }
                final String capname;
                if (loop.valDecl != null && loop.valDecl.isJsCaptured()) {
                    capname = names.createTempVariable();
                    gen.out("var ", capname, "=", loop.valueVarName, ";");
                    names.forceName(loop.valDecl, capname);
                } else {
                    capname = null;
                }

                // generate conditions as nested ifs
                for (int i=0; i<loop.conditions.size(); i++) {
                    gen.conds.specialConditions(loop.conditionVars.get(i), loop.conditions.get(i), "if", false);
                    gen.beginBlock();
                }

                // initialize iterator of next loop and get its first element
                if (!isLastLoop) {
                    ComprehensionLoopInfo nextLoop = loops.get(loopIndex+1);
                    gen.out(nextLoop.itVarName, "=");
                    nextLoop.forIterator.getSpecifierExpression().visit(gen);
                    gen.out(".iterator()"); gen.endLine(true);
                }

                gen.out("return ", elemVarName, ";");
                for (int i=0; i<=loop.conditions.size(); i++) { gen.endBlockNewLine(); }
                retainedVars.emitRetainedVars(gen);

                // for key/value iterators, value==undefined indicates that the iterator is finished
                if (loop.pattern != null) {
                    gen.out("return undefined;");
                } else {
                    gen.out("return ", finished, ";");
                }
                if (capname != null) {
                    names.forceName(loop.valDecl, null);
                }

                gen.endBlockNewLine();
            }
        }

        // generate the "next" function for the comprehension
        gen.out("return function()");
        gen.beginBlock();

        // start a do-while block for all except the innermost loop
        for (int i=1; i<loops.size(); i++) {
            gen.out("do"); gen.beginBlock();
        }

        // Check if another element is available on the innermost loop.
        // If so, evaluate the expression, advance the iterator and return the result.
        ComprehensionLoopInfo lastLoop = loops.get(loops.size()-1);
        gen.out("if(n", lastLoop.valueVarName, "()!==", (lastLoop.pattern==null)
                ? finished : "undefined", ")");
        gen.beginBlock();
        String tv = names.createTempVariable();
        final String tempVarName = names.createTempVariable();
        names.forceName(lastLoop.valDecl, tv);
        gen.out("var ", tv, "=", lastLoop.valueVarName, ",");
        if (lastLoop.pattern != null) {
            //Capture deconstructed variables here
            HashSet<Declaration> decs = new HashSet<>();
            new Destructurer(lastLoop.pattern, null, decs, "", true, false);
            for (Declaration d : decs) {
                final String newDeconstructedVarName = names.createTempVariable();
                gen.out(newDeconstructedVarName, "=", names.name(d), ",");
                names.forceName(d, newDeconstructedVarName);
            }
        }
        List<ConditionGenerator.VarHolder> captureds = null;
        if (expression.getTypeModel() != null && TypeUtils.isCallable(expression.getTypeModel())) {
            captureds = new ArrayList<>(loops.size()*2);
            for (ComprehensionLoopInfo cli : loops) {
                captureds.addAll(cli.containedVars(expression));
            }
        }
        gen.out(tempVarName, "=");
        if (captureds != null && !captureds.isEmpty()) {
            gen.out("function(");
            boolean first=true;
            for (ConditionGenerator.VarHolder vh : captureds) {
                if (!first)gen.out(",");
                gen.out(vh.name);
                first=false;
            }
            gen.out("){return ");
        }
        expression.visit(gen);
        if (captureds != null && !captureds.isEmpty()) {
            gen.out(";}(");
            boolean first=true;
            for (ConditionGenerator.VarHolder vh : captureds) {
                if (!first)gen.out(",");
                gen.out(vh.name);
                first=false;
            }
            gen.out(")");
        }
        gen.endLine(true);
        retainedVars.emitRetainedVars(gen);
        gen.out("return ", tempVarName, ";");
        gen.endBlockNewLine();

        // "while" part of the do-while loops
        for (int i=loops.size()-2; i>=0; i--) {
            gen.endBlock();
            gen.out("while(n", loops.get(i).valueVarName, "()!==",
                    (loops.get(i).pattern==null) ? finished : "undefined", ")");
            gen.endLine(true);
        }

        gen.out("return ", finished, ";");
        gen.endBlockNewLine();
        if (tail != null) {
        	// tail is set for comprehensions beginning with an "if" clause
            // we have to close the blocks that were opened by the "if"s
            for (int i = 0; i < initialIfClauses; i++) {
                gen.endBlock();
            }
            // tail contains the outer else
            gen.endLine();
            gen.out(tail);
        }
        gen.endBlock();
        gen.out(",");
        TypeUtils.printTypeArguments(that, TypeUtils.wrapAsIterableArguments(that.getTypeModel()),
                gen, false, null);
        gen.out(")");
    }

    /** Represents one of the for loops of a comprehension including the associated conditions */
    private class ComprehensionLoopInfo {
        public final Tree.ForIterator forIterator;
        public final List<Tree.ConditionList> conditions = new ArrayList<Tree.ConditionList>();
        public final List<List<ConditionGenerator.VarHolder>> conditionVars = new ArrayList<List<ConditionGenerator.VarHolder>>();
        public final String itVarName;
        public final String valueVarName;
        public final Declaration valDecl;
        public final Tree.Pattern pattern;
        private Set<ConditionGenerator.VarHolder> treeVars;

        public ComprehensionLoopInfo(Tree.Comprehension that, Tree.ForIterator forIterator) {
            this.forIterator = forIterator;
            itVarName = names.createTempVariable();
            Tree.Variable valueVar = null;
            if (forIterator instanceof Tree.ValueIterator) {
                valueVar = ((Tree.ValueIterator) forIterator).getVariable();
                pattern = null;
                valDecl = valueVar.getDeclarationModel();
                valueVarName = names.name(valDecl);
                directAccess.add(valDecl);
            } else if (forIterator instanceof Tree.PatternIterator) {
                pattern = ((Tree.PatternIterator) forIterator).getPattern();
                valueVar = null;
                valDecl = null;
                valueVarName = names.createTempVariable();
            } else {
                that.addError("No support yet for iterators of type "
                              + forIterator.getClass().getName(), Backend.JavaScript);
                valueVarName = null;
                valDecl = null;
                pattern = null;
                return;
            }
        }

        public Set<ConditionGenerator.VarHolder> containedVars(Tree.Expression that) {
            final Set<Declaration> expdecs = ClosureHelper.declarationsInExpression(that);
            treeVars = new HashSet<>(expdecs.size());
            for (List<ConditionGenerator.VarHolder> lvh : conditionVars) {
                for (ConditionGenerator.VarHolder vh : lvh) {
                    if (vh.var != null && expdecs.contains(vh.var)) {
                        treeVars.add(vh);
                    }
                    if (vh.captured != null) {
                        for (Value cap : vh.captured) {
                            if (expdecs.contains(cap)) {
                                treeVars.add(vh);
                            }
                        }
                    }
                }
            }
            return treeVars;
        }
    }
}
