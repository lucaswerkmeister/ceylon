/*
 * Copyright Red Hat Inc. and/or its affiliates and other contributors
 * as indicated by the authors tag. All rights reserved.
 *
 * This copyrighted material is made available to anyone wishing to use,
 * modify, copy, or redistribute it subject to the terms and conditions
 * of the GNU General Public License version 2.
 * 
 * This particular file is subject to the "Classpath" exception as provided in the 
 * LICENSE file that accompanied this code.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT A
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License,
 * along with this distribution; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA  02110-1301, USA.
 */
@nomodel
interface Bug633Ranged<in Index, out Span>{
    shared formal void span(Index from);
}

@nomodel
interface Bug633Empty satisfies Bug633Ranged<Integer, Bottom> {
    //shared actual formal void span(Integer from);
}

@nomodel
class Bug633EmptyImpl() satisfies Bug633Empty {
    shared actual void span(Integer from){}
}

@nomodel
void bug633(){
    Bug633EmptyImpl a = Bug633EmptyImpl();
    Bug633Empty b = Bug633EmptyImpl();
    Bug633Ranged<Integer, Integer> c = Bug633EmptyImpl();
    Integer[] seq = {};
}
