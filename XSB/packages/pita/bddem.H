/* File:      pita_lib.H
** Author(s): Fabrizio Riguzzi and Terrance Swift
** Contact:   fabrizio.riguzzi@unife.it, xsb-contact@cs.sunysb.edu
**
** Copyright (C) Copyright: Fabrizio Riguzzi and Terrance Swift
**                          ENDIF - University of Ferrara
**                          Centro de Inteligencia Artificial,
**                          Universidade Nova de Lisboa, Portugal
**
** XSB is free software; you can redistribute it and/or modify it under the
** terms of the GNU Library General Public License as published by the Free
** Software Foundation; either version 2 of the License, or (at your option)
** any later version.
**
** XSB is distributed in the hope that it will be useful, but WITHOUT ANY
** WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
** FOR A PARTICULAR PURPOSE.  See the GNU Library General Public License for
** more details.
**
** You should have received a copy of the GNU Library General Public License
** along with XSB; if not, write to the Free Software Foundation,
** Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
**
*/

:- export
  init_em/1,init_ex/2,init/1,end_em/1,end_ex/1,end/1,
  one/2,zero/2,and/4,or/4,bdd_not/3,
  ret_prob/3,equality/4,add_var/4,
  add_abd_var/4,ret_abd_prob/4,
  add_query_var/4,ret_map_prob/4,
  make_query_var/3,create_dot/3,create_dot_string/3,
  em/9,rand_seed/1,
  gamma_sample/3,
  gauss_sample/3,
  uniform_sample/1,
  dirichlet_sample/2,
  symmetric_dirichlet_sample/3,
  discrete_sample/2.

:- foreign_pred init_em(-retval) from 
	init_em_pl:int.

:- foreign_pred end_em(+ex_data) from 
	end_em_pl(ex_data:int):void.

:- foreign_pred init_ex(+ex_data,-retval) from 
	init_ex_pl(ex_data:int):int.

:- foreign_pred end_ex(+ex_data) from 
	end_ex_pl(ex_data:int):void.

:- foreign_pred add_var(+env,+probs,+rule,-retval) from 
	add_var_pl(env:int,probs:term,rule:int):int.

:- foreign_pred add_query_var(+env,+probs,+rule,-retval) from 
	add_query_var_pl(env:int,probs:term,rule:int):int.

:- foreign_pred add_abd_var(+env,+probs,+rule,-retval) from 
	add_abd_var_pl(env:int,probs:term,rule:int):int.

:- foreign_pred equality(+env,+varIndex,+value,-retval) from 
	equality_pl(env:int,varIndex:int,value:int):int.

:- foreign_pred and(+env,+nodea,+nodeb,-retval) from 
	and_pl(env:int,nodea:int,nodeb:int):int.
	
:- foreign_pred one(+env,-retval) from 
	one_pl(env:int):int. 

:- foreign_pred zero(+env,-retval) from 
	zero_pl(env:int):int. 

:- foreign_pred or(+env,+nodea,+nodeb,-retval) from 
	or_pl(env:int,nodea:int,nodeb:int):int. 

:- foreign_pred bdd_not(+env,+node,-retval) from 
	bdd_not_pl(env:int,node:int):int.  

:- foreign_pred create_dot(+env,+node,+file) from 
	create_dot_pl(env:int,node:int,file:string):void. 

:- foreign_pred create_dot_string(+env,+node,-dotstring) from 
	create_dot_string_pl(env:int,node:int,dotstring:stringptr):void. 

:- foreign_pred init(-retval) from 
	init_pl:int.

:- foreign_pred end(+env) from 
	end_pl(env:int):void.

:- foreign_pred ret_prob(+env,+node, -retval) from 
	ret_prob_pl(env:int,node:int):float.

:- foreign_pred ret_abd_prob(+env,+node,-retval,-expl) from 
	ret_abd_prob_pl(env:int,node:int,expl:termptr):float.

:- foreign_pred ret_map_prob(+env,+node,-retval,-expl) from 
	ret_map_prob_pl(env:int,node:int,expl:termptr):float.

:- foreign_pred ret_vit_prob(+env,+node,-retval,-expl) from 
	ret_vit_prob_pl(env:int,node:int,expl:termptr):float.

:- foreign_pred reorder(+env) from
        reorder_pl(env:int):void.

:- foreign_pred make_query_var(+env,+varIndex,-retval) from 
	make_query_var_pl(env:int,varIndex:int):int.

:- foreign_pred em(+ex_data,+ruleInfo,+nodesTerm,+ea,+er,+iter,-retval,-out) from 
	em_pl(ex_data:int,ruleInfo:term,nodesTerm:term,ea:float,er:float,iter:int,
	out:termptr):float.

:- foreign_pred gamma_sample(+shape,+scale,-retval) from 
	gamma_sample_pl(shape:float,scale:float):float.

:- foreign_pred gauss_sample(+mean,+var,-retval) from 
	gauss_sample_pl(mean:float,var:float):float.

:- foreign_pred uniform_sample(-retval) from 
	uniform_sample_pl:float.

:- foreign_pred dirichlet_sample(+alphaterm,-sample_term) from 
	dirichlet_sample_pl(alphaterm:term,sample_term:termptr):void.

:- foreign_pred symmetric_dirichlet_sample(+alpha,+k,-sample_term) from 
	symmetric_dirichlet_sample_pl(alpha:float,k:int,sample_term:termptr):void.

:- foreign_pred discrete_sample(+thetaterm,-retval) from 
	discrete_sample_pl(thetaterm:term):int.

:- foreign_pred initial_values(+ex_data,+alpha) from 
	initial_values_pl(ex_data:int,alpha:float):void.

:- foreign_pred rand_seed(+seed) from 
	rand_seed_pl(seed:int):void.

:- ldoption('-Lcudd-3.0.0/cudd/.libs/ -lcudd -lm').    
