/*******************************************************/
/* the start of the thick to thin lens converter       */
/*******************************************************/
/* pre-CVS comments, new comments are now on CVS only */
/* 20/06/2002 - MH removed ..0 ending from kickers, by putting slice_no=1 in
   the call for create_thin_obj */
/* 17/06/2002 - MH - added calls to grow_* in create_thin_obj to make sure the
   array for command parameters in long enough. */
/* 31/05/2002 - MH - new_element_nowarn removed, core dump problems from fulln.c
   deleting the element in add_to_el_list (called from new_element_nowarn).
   changes now done to make_element */
/* 29/05/2002 - MH - ->name's are now arrays not pointers */
/* 02/04/2002 - MH - corrected copy_thin_obj to copy lrad correctly */
/*                   fixed length for collim problem */
/*                   added new collimation slicing */
/* 16/04/2002 - MH - added magnet command parameter to thin_multipole */
/* 15/04/2002 - MH - changed calloc to mycalloc for HG error checking */
/* 11/4/2002  - MH - removed *l for knl conversion */
/*                 - angle is prioritised over k0 value for [rs]bend */
/*                 - sequ->beam pointer is copied over from thick sequence */
/* 10/12/2001 - MH - removed time info */
/* 4/12/2001  - MH - changed so that >5 slices from teapot == simple style */
/* 30/11/2001 - MH - warning message for no list given once now */
/* 29/11/2001 - MH - removed the possibility of a save option */
/* 27/11/2001 - MH - removed the conversion of the tilt parameter
   now I only use the k2 and k2s (or k3 and k3s...) the tilt
   has been removed */
/* 23/11/2001 - MH - added in lrad param to create_thin_obj
   but with check to see if lrad is allowed by dictionary.
   also replaced return_param_index with name_list_pos and
   a check on inform[] where needed. */
/* 19/11/2001 - MH - Initial version 1.0 of the slicer */
/* M. Hayes                                            */
/* prototyping *******************************************************/

struct element* create_thin_obj(struct element*,int slice_no);
struct sequence* seq_diet(struct sequence*);
double at_shift(int ,int );
double q_shift(int ,int );

/* this structure is used to store a lookup table of thick to thin
   element conversions already done */
struct thin_lookup
{
  struct element *thick_elem;
  struct element *thin_elem;
  int slice;
  struct thin_lookup *next;
};
struct thin_lookup *my_list = NULL;

/* this structure is used to store a lookup table of thick to thin
   sequence conversions already done */
struct thin_sequ_lookup
{
  struct sequence *thick_sequ;
  struct sequence *thin_sequ;
  struct thin_sequ_lookup *next;
};
struct thin_sequ_lookup *my_sequ_list = NULL;

/* this is used when choosing the style of slicing */
char* thin_style = NULL;
char collim_style[] = "collim";
/* this is used to return how to slice the selected elements */
struct el_list *thin_select_list = NULL;

/* code starts here **************************************************/

/* this routine interfaces to the main mad-x code to return the number
   of slices we have to use for an element */
int get_slices(struct element* elem)
{
  int slices = 0,i;
  if (thin_select_list) {
    for(i=0; i < thin_select_list->curr; i++) {
      if (elem==thin_select_list->elem[i]) {
      slices = thin_select_list->list->inform[i]; break;
      }
    }
  }
  /* must always slice to thin */
  if (slices==0) slices = 1;
  return slices;
}

int get_slices_recurse(struct element* elem)
{
  int slices =0,tmp_slices=0;
  if (elem->parent != elem->parent->parent)
    slices = get_slices_recurse(elem->parent);

  tmp_slices = get_slices(elem->parent);
  if ( slices < tmp_slices ) {
    return tmp_slices;
  } else {
    return slices;
  }
}


/* Has this element already been dieted? returns NULL for NO.*/
struct element* get_thin(struct element* thick_elem, int slice)
{
  struct thin_lookup *cur;
  if (my_list) {
    cur = my_list;
    while (cur)
      {
      if (cur->thick_elem == thick_elem && cur->slice == slice) {
        return cur->thin_elem;
      }
      cur = cur->next;
      }
  }
  return NULL;
}

/* Enter a newly dieted element */
void put_thin(struct element* thick_elem, struct element* thin_elem, int slice)
{
  struct thin_lookup *p,*cur;
  char rout_name[] = "makethin:put_thin";
  p = (struct thin_lookup*) mycalloc(rout_name,1, sizeof(struct thin_lookup));
  p->thick_elem = thick_elem;
  p->thin_elem = thin_elem;
  p->slice = slice;
  p->next = NULL;
  if (my_list) {
    cur = my_list;
    while (cur->next) {cur = cur->next;}
    cur->next = p;
  } else {
    my_list = p;
  }
  return;
}

/* Has this sequence already been dieted? returns NULL for NO.*/
struct sequence* get_thin_sequ(struct sequence* thick_sequ)
{
  struct thin_sequ_lookup *cur;
  if (my_sequ_list) {
    cur = my_sequ_list;
    while (cur)
      {
      if (cur->thick_sequ == thick_sequ) {
        return cur->thin_sequ;
      }
      cur = cur->next;
      }
  }
  return NULL;
}

/* Enter a newly dieted element */
void put_thin_sequ(struct sequence* thick_sequ, struct sequence* thin_sequ)
{
  struct thin_sequ_lookup *p,*cur;
  char rout_name[] = "makethin:put_thin_sequ";
  p = (struct thin_sequ_lookup*) mycalloc(rout_name,1, sizeof(struct thin_sequ_lookup));
  p->thick_sequ = thick_sequ;
  p->thin_sequ = thin_sequ;
  p->next = NULL;
  if (my_sequ_list) {
    cur = my_sequ_list;
    while (cur->next) {cur = cur->next;}
    cur->next = p;
  } else {
    my_sequ_list = p;
  }
  return;
}

/* makes node name from element name and slice number*/
char* make_thin_name(char* e_name, int slice)
{
  char c_dummy[128];
  sprintf(c_dummy,"%s..%d", e_name, slice);
  return buffer(c_dummy);
}

/* scale an expression by a number - or leave it NULL */
struct expression* scale_expr(struct expression* expr,double scale)
{
  if (expr) { return compound_expr(expr,0,"*",NULL,scale); }
  return NULL;
}

/* combine two parameters using compound expression */
struct expression* comb_param(struct command_parameter* param1,
              char* op, struct command_parameter* param2)
{
 return compound_expr(param1->expr,param1->double_value,op,param2->expr,param2->double_value);
}

/* returns parameter if it has been modified, otherwise NULL */
struct command_parameter* return_param(char* par, struct element* elem)
{
  int index;
  /* don't return base type definitions */
  if (elem==elem->parent) { return NULL; }

  if ((index = name_list_pos(par,elem->def->par_names))>-1
      && elem->def->par_names->inform[index] > 0)
    return elem->def->par->parameters[index];
  return NULL;
}

/* returns parameter if it has been modified, otherwise NULL  - recursively */
struct command_parameter* return_param_recurse(char* par, struct element* elem)
{
  struct command_parameter* param;
  param = return_param(par,elem);

  if (param) { return param; }
  if (elem!=elem->parent)
    return return_param_recurse(par,elem->parent);
  return NULL;
}

/* returns first parameter value found and recusively checks sub_elements */
double el_par_value_recurse(char* par, struct element* elem)
{
  if (return_param(par, elem)) return el_par_value(par,elem);
  if (elem != elem->parent)
    return el_par_value_recurse(par,elem->parent);
  return 0;
}

/* multiply the k by length and divide by slice */
struct command_parameter* scale_and_slice(struct command_parameter *kn_param,
            struct command_parameter *length_param,
            int slices, int slice_no,
            int angle_conversion, int kl_flag)
{
  int last_non_zero=-1,i;
  if (kn_param == NULL) return NULL;

  for (i=0; i<kn_param->expr_list->curr; i++) {
    if ((kn_param->expr_list->list[i]!=NULL && zero_string(kn_param->expr_list->list[i]->string)==0)
      || kn_param->double_array->a[i]!=0) {
      last_non_zero=i;
      if (kl_flag == 0 && angle_conversion==0) {
      if ((length_param->expr) || (kn_param->expr_list->list[i])) {
        kn_param->expr_list->list[i] =
          compound_expr(kn_param->expr_list->list[i],kn_param->double_array->a[i],
          "*",length_param->expr,length_param->double_value);
      } else {
        kn_param->double_array->a[i] =  kn_param->double_array->a[i] * length_param->double_value;
      }
      }
      if (slices > 1) {
      if (kn_param->expr_list->list[i])  {
        kn_param->expr_list->list[i] =
          compound_expr(kn_param->expr_list->list[i],kn_param->double_array->a[i],
          "*",NULL,q_shift(slices,slice_no));
      } else {
        kn_param->double_array->a[i] =
          kn_param->double_array->a[i] *q_shift(slices,slice_no);
      }
      }
    }
  }
  if (last_non_zero==-1) {
    delete_command_parameter(kn_param); kn_param=NULL;
  }
  return kn_param;
}

/* translate k0,k1,k2,k3 & k0s,k1s,k2s,k3s to kn{} and ks{} */
/* 26/11/01 - removed tilt param */
int translate_k(struct command_parameter* *kparam,
       struct command_parameter* *ksparam,
       struct command_parameter *angle_param,
       struct command_parameter *kn_param,
       struct command_parameter *ks_param)
{
  int i,angle_conversion=0;
/*    char *zero[1]; */
/*    zero[0] = buffer("0"); */

  if ((kparam == NULL) && (ksparam == NULL))
    fatal_error("translate_k: no kparams to convert","");

  /* if we have a angle we ignore any given k0 */
  if (angle_param) {
    kparam[0] =  new_command_parameter("k0", 2);
    angle_conversion=1; /* note we do not divide by length, just to multiply again afterwards */
    if (angle_param->expr) {
      kparam[0]->expr =  clone_expression(angle_param->expr);
    }
    kparam[0]->double_value = angle_param->double_value;
  }

  for (i=0; i<4; i++) {
    /* zero all the parameters */
    kn_param->expr_list->list[i] = NULL; kn_param->double_array->a[i] = 0;
    ks_param->expr_list->list[i] = NULL; ks_param->double_array->a[i] = 0;
    /* copy across the k's */
    if (kparam[i]) {
      if (kparam[i]->expr) {
      kn_param->expr_list->list[i] = clone_expression(kparam[i]->expr);
      }
      kn_param->double_array->a[i] = kparam[i]->double_value;
    }
    if (ksparam[i]) {
      if (ksparam[i]->expr) {
      ks_param->expr_list->list[i] = clone_expression(ksparam[i]->expr);
      }
      ks_param->double_array->a[i] = ksparam[i]->double_value;
    }
    /* update the number of k's in our arrays */
    kn_param->expr_list->curr++; kn_param->double_array->curr++;
    ks_param->expr_list->curr++; ks_param->double_array->curr++;
  }

  return angle_conversion;
}

/* adds a node to the end of a sequence */
void seq_diet_add(struct node* node, struct sequence* sequ)
{
  if (sequ->start == NULL) { /* first node in new sequence? */
    sequ->start = node;
    sequ->end = node;
    node->next = NULL;
    node->previous = NULL;
  } else { /* no? then add to end */
    sequ->end->next = node;
    node->previous  = sequ->end;
    sequ->end = node;
  }
  add_to_node_list(node, 0, sequ->nodes);

  return;
}

/* adds a sequence to a sequence */
void seq_diet_add_sequ(struct node* thick_node, struct sequence* sub_sequ, struct sequence* sequ)
{
  struct node* node = new_sequ_node(sub_sequ, thick_node->occ_cnt); /* 1 is the occ_cnt*/
  node->length = 0;
  node->at_value = thick_node->at_value;
  if (node->at_expr) {
    node->at_expr = clone_expression(thick_node->at_expr);
  }
  seq_diet_add(node,sequ);
  return;
}

/* creates new magnetic elem -
   NB all parameters are cloned - except for kn_param and ks_param
   which have to be set up explicitly */

struct element* make_thin_elem(char* name, struct element* thin_elem_parent,
               struct command_parameter *at_param,
               struct command_parameter *from_param,
               struct command_parameter *length_param,
               struct command_parameter *kn_param,
               struct command_parameter *ks_param,
               struct command_parameter *apertype_param,
               struct command_parameter *aper_param,
               struct command_parameter *bv_param,
               struct command_parameter *tilt_param,
               int slices, int slice_no)
{
  struct command* cmd;
  struct element* thin_elem = NULL;
  char *thin_name;

  /* set up new multipole command */
  cmd = new_command(buffer("thin_multipole"), 11, 11, /* max num names, max num param */
           buffer("element"), buffer("none"), 0, 8); /* 0 is link, multipole is 8 */

  cmd->par->parameters[cmd->par->curr] = new_command_parameter("magnet", 2);
  cmd->par->parameters[cmd->par->curr]->double_value = 1;
  add_to_name_list("magnet",0,cmd->par_names); cmd->par->curr++;

  if (at_param) {
    cmd->par->parameters[cmd->par->curr] = clone_command_parameter(at_param);
    add_to_name_list("at",1,cmd->par_names); cmd->par->curr++;
  }
  if (from_param) {
    cmd->par->parameters[cmd->par->curr] = clone_command_parameter(from_param);
    add_to_name_list("from",1,cmd->par_names); cmd->par->curr++;
  }
  if (length_param) {
    cmd->par->parameters[cmd->par->curr] = new_command_parameter("l", 2);
    cmd->par->parameters[cmd->par->curr]->double_value = 0;
    add_to_name_list("l",1,cmd->par_names); cmd->par->curr++;

    cmd->par->parameters[cmd->par->curr] = clone_command_parameter(length_param);
    strcpy(cmd->par->parameters[cmd->par->curr]->name,"lrad");
    if (slices > 1) {
      if (cmd->par->parameters[cmd->par->curr]->expr) {
      cmd->par->parameters[cmd->par->curr]->expr =
        compound_expr(cmd->par->parameters[cmd->par->curr]->expr,0.,"/",NULL,slices);
      } else {
      cmd->par->parameters[cmd->par->curr]->double_value =
        cmd->par->parameters[cmd->par->curr]->double_value / slices;
      }
    }
    add_to_name_list("lrad",1,cmd->par_names); cmd->par->curr++;
  }
  if (kn_param) {
    cmd->par->parameters[cmd->par->curr] = kn_param;
    add_to_name_list("knl",1,cmd->par_names); cmd->par->curr++;
  }
  if (ks_param) {
    cmd->par->parameters[cmd->par->curr] = ks_param;
    add_to_name_list("ksl",1,cmd->par_names); cmd->par->curr++;
  }
  if (apertype_param) {
    cmd->par->parameters[cmd->par->curr] = clone_command_parameter(apertype_param);
    add_to_name_list("apertype",1,cmd->par_names); cmd->par->curr++;
  }
  if (aper_param) {
    cmd->par->parameters[cmd->par->curr] = clone_command_parameter(aper_param);
    add_to_name_list("aperture",1,cmd->par_names); cmd->par->curr++;
  }
  if (bv_param) {
    cmd->par->parameters[cmd->par->curr] = clone_command_parameter(bv_param);
    add_to_name_list("bv",1,cmd->par_names); cmd->par->curr++;
  }
  if (tilt_param) {
    cmd->par->parameters[cmd->par->curr] = clone_command_parameter(tilt_param);
    add_to_name_list("tilt",1,cmd->par_names); cmd->par->curr++;
  }
/* create element with this command */
  if (slices==1 && slice_no==1) {
    thin_name=buffer(name);
  } else {
    thin_name = make_thin_name(name,slice_no);
  }

  if (thin_elem_parent) {
    thin_elem = make_element(thin_name,thin_elem_parent->name,cmd,-1);
  } else {
    thin_elem = make_element(thin_name,"multipole",cmd,-1);
  }
  thin_elem->length = 0;
  thin_elem->bv = el_par_value("bv",thin_elem);
  if (thin_elem_parent && thin_elem_parent->bv) {
    thin_elem->bv = thin_elem_parent->bv;
  }
  return thin_elem;
}

/* creates the thin magnetic element - recursively */
struct element* create_thin_pole(struct element* thick_elem, int slice_no)
{
  struct command_parameter *angle_param = NULL;
  struct command_parameter *kparam[4], *ksparam[4];
  struct command_parameter *length_param = NULL;
  struct command_parameter *kn_param = NULL,*ks_param = NULL;
  struct element* thin_elem_parent = NULL;
  struct element* thin_elem = NULL;
  int angle_conversion = 0;
  int slices = 1;
  int knl_flag = 0,ksl_flag = 0;

  if (thick_elem == thick_elem->parent) {
    return NULL;
  } else {
    thin_elem_parent = create_thin_pole(thick_elem->parent,slice_no);
  }

  /* check to see if we've already done this one */
  thin_elem = get_thin(thick_elem,slice_no);
  if (thin_elem) return thin_elem;

  length_param = return_param_recurse("l",thick_elem);
  angle_param  = return_param_recurse("angle",thick_elem);
  kparam[0]    = return_param_recurse("k0",thick_elem);
  kparam[1]    = return_param_recurse("k1",thick_elem);
  kparam[2]    = return_param_recurse("k2",thick_elem);
  kparam[3]    = return_param_recurse("k3",thick_elem);
  ksparam[0]    = return_param_recurse("k0s",thick_elem);
  ksparam[1]    = return_param_recurse("k1s",thick_elem);
  ksparam[2]    = return_param_recurse("k2s",thick_elem);
  ksparam[3]    = return_param_recurse("k3s",thick_elem);
  kn_param   = return_param_recurse("knl",thick_elem);
  ks_param   = return_param_recurse("ksl",thick_elem);
  if (kn_param) {kn_param = clone_command_parameter(kn_param); knl_flag++;}
  if (ks_param) {ks_param = clone_command_parameter(ks_param); ksl_flag++;}

  /* translate k0,k1,k2,k3,angle */
  if ((kparam[0] || kparam[1] || kparam[2] || kparam[3] || angle_param
       || ksparam[0] || ksparam[1] || ksparam[2] || ksparam[3])
      && (kn_param==NULL && ks_param==NULL)) {
    kn_param = new_command_parameter("knl", 12);
    kn_param->expr_list = new_expr_list(10);
    kn_param->double_array = new_double_array(10);
    ks_param = new_command_parameter("ksl", 12);
    ks_param->expr_list = new_expr_list(10);
    ks_param->double_array = new_double_array(10);
    angle_conversion = translate_k(kparam,ksparam,angle_param,kn_param,ks_param);
  }

  slices = get_slices_recurse(thick_elem);

  kn_param = scale_and_slice(kn_param,length_param,slices,slice_no,
             angle_conversion,knl_flag+ksl_flag);
  ks_param = scale_and_slice(ks_param,length_param,slices,slice_no,
             angle_conversion,knl_flag+ksl_flag);


  thin_elem = make_thin_elem(thick_elem->name, thin_elem_parent,
                        return_param("at",thick_elem),return_param("from",thick_elem),
        length_param,kn_param,ks_param,return_param_recurse("apertype",thick_elem),
        return_param_recurse("aperture",thick_elem),return_param("bv",thick_elem),
        return_param("tilt",thick_elem),slices,slice_no);
  put_thin(thick_elem,thin_elem,slice_no);
  return thin_elem;
}

/* put in one of those nice marker kind of things */
struct node* new_marker(struct node *thick_node, double at, struct expression *at_expr)
{
  struct node* node=NULL;
  struct element* elem=NULL;

  int pos;
    struct command* p;
  struct command* clone;

  if (thick_node->p_elem) {
    pos = name_list_pos("marker", defined_commands->list);
    /* clone = clone_command(defined_commands->commands[pos]); */
        p = defined_commands->commands[pos];
        clone = new_command(p->name, 0, 0, p->module, p->group, p->link_type,
        p->mad8_type);
    elem = make_element(thick_node->p_elem->name, "marker", clone,-1);
    node = new_elem_node(elem, thick_node->occ_cnt);
    strcpy(node->name, thick_node->name);
    node->occ_cnt = thick_node->occ_cnt;
    node->at_value = at;
    if (at_expr) { node->at_expr = clone_expression(at_expr); }
    node->from_name = thick_node->from_name;
  } else {
    fatal_error("Oh dear, this is not an element!",thick_node->name);
  }

  return node;
}

/* adds a thin elem in sliced nodes to the end of a sequence */
void seq_diet_add_elem(struct node* node, struct sequence* to_sequ)
{
  struct command_parameter *at_param, *length_param;
  struct expression *l_expr = NULL, *at_expr = NULL;
  struct node* thin_node;
  struct element* elem;
  double length = 0, at = 0;
  int i,middle=-1,slices = 1;
  char* old_thin_style;

  old_thin_style = NULL;
  if (strstr(node->base_name,"collimator")) {
    elem = create_thin_obj(node->p_elem,1);
    old_thin_style = thin_style;
    thin_style = collim_style;
  } else {
    elem = create_thin_pole(node->p_elem,1); /* get info from first slice */
  }
  slices = get_slices_recurse(node->p_elem);

  at_param = return_param_recurse("at",elem);
  length_param = return_param_recurse("l",node->p_elem); /*get original length*/
  if (length_param) {l_expr  = length_param->expr;}
  if (at_param)     {at_expr = at_param->expr;}

  at     = el_par_value_recurse("at", elem);
  length = el_par_value_recurse("l",node->p_elem);

  if (node->at_expr)  { at_expr = node->at_expr; }
  if (node->at_value != zero) { at = node->at_value; }
  if (node->length   != zero) { length = node->length; }
  /* note that a properly created clone node will contain the length of the element */
  /* this will override all other definitions and hence the already sliced element length
     is irrelevant */

  if (slices>1) { /* sets after which element I should put the marker */
    middle = abs(slices/2);
  }

  for (i=0; i<slices; i++) {
    if (strstr(node->base_name,"collimator")) {
      elem = create_thin_obj(node->p_elem,i+1);
    } else {
      elem = create_thin_pole(node->p_elem,i+1);
    }
    thin_node = new_elem_node(elem, node->occ_cnt);
    thin_node->length   = 0.0;
    thin_node->from_name = buffer(node->from_name);
    if (fabs(at_shift(slices,i+1))>0.0) {
      if (at_expr || l_expr) {
      thin_node->at_expr =
        compound_expr(at_expr,at,"+",scale_expr(l_expr,at_shift(slices,i+1)),
        length*at_shift(slices,i+1));
      }
    } else {
      if (at_expr) thin_node->at_expr = clone_expression(at_expr);
    }
    thin_node->at_value = at + length*at_shift(slices,i+1);

    if (i==middle) seq_diet_add(new_marker(node,at,at_expr),to_sequ);
    seq_diet_add(thin_node,to_sequ);
  }
  if (strstr(node->base_name,"collimator")) {thin_style=old_thin_style;}
  return;
}

/* creates the thin non-magnetic element - recursively */
struct element* create_thin_obj(struct element* thick_elem, int slice_no)
{
  struct element* thin_elem_parent = NULL;
  struct element* thin_elem = NULL;
  struct command* cmd = NULL;
  struct command_parameter*  length_param= NULL;
  int length_i = -1,lrad_i = -1,slices=1;
  char* thin_name = NULL;

  if (thick_elem == thick_elem->parent) {
    return NULL;
  } else {
    thin_elem_parent = create_thin_obj(thick_elem->parent,slice_no);
  }

  /* check to see if we've already done this one */
  thin_elem = get_thin(thick_elem,slice_no);
  if (thin_elem) return thin_elem;

  /* set up new multipole command */
  cmd = clone_command(thick_elem->def);
  length_param = return_param_recurse("l",thick_elem);
  length_i = name_list_pos("l",thick_elem->def->par_names);
  lrad_i   = name_list_pos("lrad",thick_elem->def->par_names);
  if (length_param) {
    if (lrad_i > -1 && thick_elem->def->par_names->inform[lrad_i]>0) {
      /* already exists so replace lrad */
      cmd->par->parameters[lrad_i]->double_value = cmd->par->parameters[length_i]->double_value;
      if (cmd->par->parameters[length_i]->expr) {
      if (cmd->par->parameters[lrad_i]->expr)
        delete_expression(cmd->par->parameters[lrad_i]->expr);
      cmd->par->parameters[lrad_i]->expr =
        clone_expression(cmd->par->parameters[length_i]->expr);
      }
    } else { /* doesn't exist */
      if (name_list_pos("lrad",thick_elem->base_type->def->par_names)>-1) {
      /* add lrad only if allowed by element */
      if (cmd->par->curr == cmd->par->max) grow_command_parameter_list(cmd->par);
      if (cmd->par_names->curr == cmd->par_names->max)
        grow_name_list(cmd->par_names);
      cmd->par->parameters[cmd->par->curr] = clone_command_parameter(length_param);
      add_to_name_list("lrad",1,cmd->par_names);
      cmd->par->parameters[name_list_pos("lrad",cmd->par_names)]->expr =
        clone_expression(cmd->par->parameters[length_i]->expr);
      cmd->par->curr++;
      }
    }
  }

  if (length_i > -1) {
    cmd->par->parameters[length_i]->double_value = 0;
    cmd->par->parameters[length_i]->expr = NULL;
  }
  if (strstr(thick_elem->base_type->name,"collimator")) {
    slices = get_slices_recurse(thick_elem);
  }
  if (slices==1 && slice_no==1) {
    thin_name=buffer(thick_elem->name);
  } else {
    thin_name=make_thin_name(thick_elem->name,slice_no);
  }

  if (thin_elem_parent) {
    thin_elem = make_element(thin_name,thin_elem_parent->name,cmd,-1);
  } else {
    thin_elem = make_element(thin_name,thick_elem->base_type->name,cmd,-1);
  }
  thin_elem->length = 0;
  thin_elem->bv = el_par_value("bv",thin_elem);

  put_thin(thick_elem,thin_elem,slice_no);
  return thin_elem;
}

/* this copies an element node and sets the length to zero
   and radiation length to the length
   to be used for "copying" optically neutral elements */
struct node* copy_thin(struct node* thick_node)
{
  struct node* thin_node = NULL;

  thin_node = clone_node(thick_node, 0);
  thin_node->length=0;
  thin_node->p_elem->length=0;
  /* if we have a non zero length then an lrad has to be created */
  if (el_par_value("l",thick_node->p_elem)>zero)
    { thin_node->p_elem = create_thin_obj(thick_node->p_elem,1); }

  return thin_node;
}

/* this decides how to split an individual node and
   sends it onto the thin_sequ builder */
void seq_diet_node(struct node* thick_node, struct sequence* thin_sequ)
{
  struct node* thin_node;
  if (thick_node->p_elem) { /* this is an element to split and add */
    if (el_par_value("l",thick_node->p_elem)==zero) /* if it's already thin copy it directly*/
    {
      seq_diet_add(thin_node = copy_thin(thick_node),thin_sequ);
    } else { /* we have to slim it down a bit...*/
      if (strcmp(thick_node->base_name,"marker") == 0      ||
        strcmp(thick_node->base_name,"hmonitor") == 0    ||
        strcmp(thick_node->base_name,"vmonitor") == 0    ||
        strcmp(thick_node->base_name,"monitor") == 0     ||
        strcmp(thick_node->base_name,"vkicker") == 0     ||
        strcmp(thick_node->base_name,"hkicker") == 0     ||
        strcmp(thick_node->base_name,"kicker") == 0      ||
        strcmp(thick_node->base_name,"rfcavity") == 0
        ) {
      seq_diet_add(thin_node = copy_thin(thick_node),thin_sequ);
      /*   delete_node(thick_node); */
      /* special cavity list stuff */
      if (strcmp(thin_node->p_elem->base_type->name, "rfcavity") == 0 &&
          find_element(thin_node->p_elem->name, thin_sequ->cavities) == NULL)
        add_to_el_list(&thin_node->p_elem, 0, thin_sequ->cavities, 0);
      } else if (strcmp(thick_node->base_name,"rbend") == 0       ||
        strcmp(thick_node->base_name,"sbend") == 0       ||
        strcmp(thick_node->base_name,"quadrupole") == 0  ||
        strcmp(thick_node->base_name,"sextupole") == 0   ||
        strcmp(thick_node->base_name,"octupole") == 0    ||
        strcmp(thick_node->base_name,"multipole") == 0
        || /* special spliting required. */
        strcmp(thick_node->base_name,"rcollimator") == 0 ||
        strcmp(thick_node->base_name,"ecollimator") == 0
        ) {
      seq_diet_add_elem(thick_node,thin_sequ);
      /*   delete_node(thick_node); */
      } else if (strcmp(thick_node->base_name,"drift") == 0) {
      /* ignore this as it makes no sense to slice */
      } else {
      fprintf(prt_file, "Found unknown basename %s, doing copy with length set to zero.\n",thick_node->base_name);
      seq_diet_add(copy_thin(thick_node),thin_sequ);
      /*        delete_node(thick_node); */
      }
    }
  } else if (thick_node->p_sequ) { /* this is a sequence to split and add */
    seq_diet_add_sequ(thick_node,seq_diet(thick_node->p_sequ),thin_sequ);
  } else { /* we have no idea what this is - serious error */
    fatal_error("node is not element or sequence",thick_node->base_name);
  }
}

/* slim down this sequence - this is the bit to be called recursively */
/* this actually creates the thin sequence */
struct sequence* seq_diet(struct sequence* thick_sequ)
{
  struct node *thick_node = NULL;
  struct sequence* thin_sequ;
  char name[128];
  int pos;

  /* first check to see if it had been already sliced */
  if ((thin_sequ=get_thin_sequ(thick_sequ))) return thin_sequ;

  strcpy(name,thick_sequ->name);
  fprintf(prt_file, "makethin: slicing sequence : %s\n",name);
  thin_sequ = new_sequence(name, thick_sequ->ref_flag);
  thin_sequ->start = NULL;
  thin_sequ->share = thick_sequ->share;
  thin_sequ->nested = thick_sequ->nested;
  thin_sequ->length = thick_sequ->length;
  thin_sequ->refpos = buffer(thick_sequ->refpos);
  thin_sequ->ref_flag = thick_sequ->ref_flag;
  thin_sequ->beam = thick_sequ->beam;
  if (thin_sequ->cavities != NULL)  thin_sequ->cavities->curr = 0;
  else thin_sequ->cavities = new_el_list(100);
  thick_node = thick_sequ->start;
  while(thick_node != NULL) { /* loop over current sequence */
    /* the nodes are added to the sequence in seq_diet_add() */
    seq_diet_node(thick_node,thin_sequ);
    if (thick_node == thick_sequ->end)  break;
    thick_node = thick_node->next;
  }
  thin_sequ->end->next = thin_sequ->start;
  /* now we have to move the pointer in the sequences list
     to point to our thin sequence */
  if ((pos = name_list_pos(name, sequences->list)) < 0) {
    fatal_error("unknown sequence sliced:", name);
  } else {
    sequences->sequs[pos]= thin_sequ;
    /* delete_sequence(thick_sequ) */
  }

  /* add to list of sequences sliced */
  put_thin_sequ(thick_sequ,thin_sequ);

  return thin_sequ;
}

/* This converts the MAD-X command to something I can use
 if a file has been specified we send the command to exec_save
 which writes the file for us */
void makethin(struct in_cmd* cmd)
{
  struct sequence *thick_sequ = NULL ,*thin_sequ = NULL;
  struct name_list* nl = cmd->clone->par_names;
  struct command_parameter_list* pl = cmd->clone->par;
  char *name = NULL;
  int pos,pos2;
/*    time_t start; */

/*    start = time(NULL); */
  pos = name_list_pos("style", nl);
  if (nl->inform[pos] && (name = pl->parameters[pos]->string))
    {
      thin_style = buffer(pl->parameters[pos]->string);
      fprintf(prt_file, "makethin: style chosen : %s\n",thin_style);
    }
  /* selection criteria */
  if (slice_select->curr > 0) {
    set_selected_elements(); thin_select_list = selected_elements;
  }
  if (thin_select_list == NULL) {
    warning("makethin: no selection list,","slicing all to one thin lens.");
  } else if (thin_select_list->curr == 0) {
    warning("makethin: selection list empty,","slicing all to one thin lens.");
  }
  pos = name_list_pos("sequence", nl);
  if (nl->inform[pos] && (name = pl->parameters[pos]->string))
    {
     if ((pos2 = name_list_pos(name, sequences->list)) >= 0)
        {
         thick_sequ = sequences->sequs[pos2];
         thin_sequ = seq_diet(thick_sequ);
           remove_from_name_list(thin_sequ->name, line_list->list);
        }
     else warning("unknown sequence ignored:", name);
    }
    else warning("makethin without sequence:", "ignored");
/*    fprintf(prt_file, "makethin: finished in %f seconds.\n",difftime(time(NULL),start)); */
  thin_select_list = NULL;
}

/*************************************************************************/
/* these are the routines to determine the method of splitting */
/* note slice number is counted from 1 NOT 0 */

/* return at relative shifts from center of unsliced magnet */
double simple_at_shift(int slices,int slice_no)
{
  double at = 0;
  at = ((double) 2*slice_no-1)/((double) 2*slices)-0.5;
  return at;
}

double teapot_at_shift(int slices,int slice_no)
{
  double at = 0;
  switch (slices) {
  case 1:
    at = 0.;
    break;
  case 2:
    if (slice_no == 1) at = -1./3.;
    if (slice_no == 2) at = +1./3.;
    break;
  case 3:
    if (slice_no == 1) at = -3./8.;
    if (slice_no == 2) at = 0.;
    if (slice_no == 3) at = +3./8.;
    break;
  case 4:
    if (slice_no == 1) at = -2./5.;
    if (slice_no == 2) at = -2./15.;
    if (slice_no == 3) at = +2./15.;
    if (slice_no == 4) at = +2./5.;
    break;
  }
  /* return the simple style if slices > 4 */
  if (slices > 4) { at = simple_at_shift(slices,slice_no); }
  return at;
}

double collim_at_shift(int slices,int slice_no)
{
  double at = 0;
  if (slices==1) {
    at = 0.0;
  } else {
    at = (slice_no-1.0)/(slices-1.0)-0.5;
  }
  return at;
}

/* return at relative strength shifts from unsliced magnet */
double teapot_q_shift(int slices,int slice_no)
{
  return 1./slices;
}

double simple_q_shift(int slices,int slice_no)
{
  return 1./slices;
}

double collim_q_shift(int slices,int slice_no)
{ /* pointless actually, but it pleases symmetrically */
  return 1./slices;
}


/* return at relative shifts from center of unsliced magnet */
double at_shift(int slices,int slice_no)
{
  if (thin_style == NULL || strcmp(thin_style,"teapot")==0) {
    return teapot_at_shift(slices,slice_no);
  } else if (strcmp(thin_style,"simple")==0) {
    return simple_at_shift(slices,slice_no);
  } else if (strcmp(thin_style,"collim")==0) {
    return collim_at_shift(slices,slice_no);
  } else {
    fatal_error("makethin: Style chosen not known:",thin_style);
  }
  return 0;
}

/* return at relative strength shifts from unsliced magnet */
double q_shift(int slices,int slice_no)
{
  if (thin_style == NULL || strcmp(thin_style,"teapot")==0) {
    return teapot_q_shift(slices,slice_no);
  } else if (strcmp(thin_style,"simple")==0) {
    return simple_q_shift(slices,slice_no);
  } else if (strcmp(thin_style,"collim")==0) {
    return collim_q_shift(slices,slice_no);
  } else {
    fatal_error("makethin: Style chosen not known:",thin_style);
  }
  return 0;
}


/*************************************************************************/
