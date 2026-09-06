"use strict";(self.webpackChunkfrontend=self.webpackChunkfrontend||[]).push([["467"],{21879(e,t,i){i.d(t,{A:()=>a});var n=i(18348),r=i(53098);let a=function(e){return"number"==typeof e||(0,r.A)(e)&&"[object Number]"==(0,n.A)(e)}},85684(e,t,i){i.d(t,{A:()=>v});var n=i(44041),r=i(90290),a=i(49359),o=i(50922),l=i(79623),c=i(75454),s=i(69598),d=i(14957),u=i(20649);let h={name:"Flex",self:function(){return u.A}},b=Object.assign(Object.assign({},a.A.props),{align:String,justify:{type:String,default:"start"},inline:Boolean,vertical:Boolean,reverse:Boolean,size:{type:[String,Number,Array],default:"medium"},wrap:{type:Boolean,default:!0}}),v=(0,r.pM)({name:"Flex",props:b,setup(e){let{mergedClsPrefixRef:t,mergedRtlRef:i}=(0,o.Ay)(e),s=(0,a.A)("Flex","-flex",void 0,h,e,t);return{rtlEnabled:(0,l.I)("Flex",i,t),mergedClsPrefix:t,margin:(0,r.EW)(()=>{let{size:t}=e;if(Array.isArray(t))return{horizontal:t[0],vertical:t[1]};if("number"==typeof t)return{horizontal:t,vertical:t};let{self:{[(0,c.cF)("gap",t)]:i}}=s.value,{row:r,col:a}=(0,n.t8)(i);return{horizontal:(0,n.eV)(a),vertical:(0,n.eV)(r)}})}},render(){let{vertical:e,reverse:t,align:i,inline:n,justify:a,margin:o,wrap:l,mergedClsPrefix:c,rtlEnabled:u}=this,h=(0,s.B)((0,d.$)(this),!1);return h.length?(0,r.h)("div",{role:"none",class:[`${c}-flex`,u&&`${c}-flex--rtl`],style:{display:n?"inline-flex":"flex",flexDirection:e&&!t?"column":e&&t?"column-reverse":!e&&t?"row-reverse":"row",justifyContent:a,flexWrap:!l||e?"nowrap":"wrap",alignItems:i,gap:`${o.vertical}px ${o.horizontal}px`}},h):null}})},45679(e,t,i){let n;i.d(t,{A:()=>$});var r=i(44041),a=i(5562),o=i(90290),l=i(39819),c=i(73445),s=i(49359),d=i(50922),u=i(83370),h=i(4019),b=i(16680),v=i(75454),p=i(49521),f=i(3755),g=i(28880),w=i(98090);let m={name:"Switch",common:g.A,self:function(e){let{primaryColor:t,opacityDisabled:i,borderRadius:n,textColor3:r}=e;return Object.assign(Object.assign({},w.A),{iconColor:r,textColor:"white",loadingColor:t,opacityDisabled:i,railColor:"rgba(0, 0, 0, .14)",railColorActive:t,buttonBoxShadow:"0 1px 4px 0 rgba(0, 0, 0, 0.3), inset 0 0 1px 0 rgba(0, 0, 0, 0.05)",buttonColor:"#FFF",railBorderRadiusSmall:n,railBorderRadiusMedium:n,railBorderRadiusLarge:n,buttonBorderRadiusSmall:n,buttonBorderRadiusMedium:n,buttonBorderRadiusLarge:n,boxShadowFocus:`0 0 0 2px ${(0,f.QX)(t,{alpha:.2})}`})}};var y=i(58454);let x=(0,v.cB)("switch",`
 height: var(--n-height);
 min-width: var(--n-width);
 vertical-align: middle;
 user-select: none;
 -webkit-user-select: none;
 display: inline-flex;
 outline: none;
 justify-content: center;
 align-items: center;
`,[(0,v.cE)("children-placeholder",`
 height: var(--n-rail-height);
 display: flex;
 flex-direction: column;
 overflow: hidden;
 pointer-events: none;
 visibility: hidden;
 `),(0,v.cE)("rail-placeholder",`
 display: flex;
 flex-wrap: none;
 `),(0,v.cE)("button-placeholder",`
 width: calc(1.75 * var(--n-rail-height));
 height: var(--n-rail-height);
 `),(0,v.cB)("base-loading",`
 position: absolute;
 top: 50%;
 left: 50%;
 transform: translateX(-50%) translateY(-50%);
 font-size: calc(var(--n-button-width) - 4px);
 color: var(--n-loading-color);
 transition: color .3s var(--n-bezier);
 `,[(0,y.N)({left:"50%",top:"50%",originalTransform:"translateX(-50%) translateY(-50%)"})]),(0,v.cE)("checked, unchecked",`
 transition: color .3s var(--n-bezier);
 color: var(--n-text-color);
 box-sizing: border-box;
 position: absolute;
 white-space: nowrap;
 top: 0;
 bottom: 0;
 display: flex;
 align-items: center;
 line-height: 1;
 `),(0,v.cE)("checked",`
 right: 0;
 padding-right: calc(1.25 * var(--n-rail-height) - var(--n-offset));
 `),(0,v.cE)("unchecked",`
 left: 0;
 justify-content: flex-end;
 padding-left: calc(1.25 * var(--n-rail-height) - var(--n-offset));
 `),(0,v.c)("&:focus",[(0,v.cE)("rail",`
 box-shadow: var(--n-box-shadow-focus);
 `)]),(0,v.cM)("round",[(0,v.cE)("rail","border-radius: calc(var(--n-rail-height) / 2);",[(0,v.cE)("button","border-radius: calc(var(--n-button-height) / 2);")])]),(0,v.C5)("disabled",[(0,v.C5)("icon",[(0,v.cM)("rubber-band",[(0,v.cM)("pressed",[(0,v.cE)("rail",[(0,v.cE)("button","max-width: var(--n-button-width-pressed);")])]),(0,v.cE)("rail",[(0,v.c)("&:active",[(0,v.cE)("button","max-width: var(--n-button-width-pressed);")])]),(0,v.cM)("active",[(0,v.cM)("pressed",[(0,v.cE)("rail",[(0,v.cE)("button","left: calc(100% - var(--n-offset) - var(--n-button-width-pressed));")])]),(0,v.cE)("rail",[(0,v.c)("&:active",[(0,v.cE)("button","left: calc(100% - var(--n-offset) - var(--n-button-width-pressed));")])])])])])]),(0,v.cM)("active",[(0,v.cE)("rail",[(0,v.cE)("button","left: calc(100% - var(--n-button-width) - var(--n-offset))")])]),(0,v.cE)("rail",`
 overflow: hidden;
 height: var(--n-rail-height);
 min-width: var(--n-rail-width);
 border-radius: var(--n-rail-border-radius);
 cursor: pointer;
 position: relative;
 transition:
 opacity .3s var(--n-bezier),
 background .3s var(--n-bezier),
 box-shadow .3s var(--n-bezier);
 background-color: var(--n-rail-color);
 `,[(0,v.cE)("button-icon",`
 color: var(--n-icon-color);
 transition: color .3s var(--n-bezier);
 font-size: calc(var(--n-button-height) - 4px);
 position: absolute;
 left: 0;
 right: 0;
 top: 0;
 bottom: 0;
 display: flex;
 justify-content: center;
 align-items: center;
 line-height: 1;
 `,[(0,y.N)()]),(0,v.cE)("button",`
 align-items: center; 
 top: var(--n-offset);
 left: var(--n-offset);
 height: var(--n-button-height);
 width: var(--n-button-width-pressed);
 max-width: var(--n-button-width);
 border-radius: var(--n-button-border-radius);
 background-color: var(--n-button-color);
 box-shadow: var(--n-button-box-shadow);
 box-sizing: border-box;
 cursor: inherit;
 content: "";
 position: absolute;
 transition:
 background-color .3s var(--n-bezier),
 left .3s var(--n-bezier),
 opacity .3s var(--n-bezier),
 max-width .3s var(--n-bezier),
 box-shadow .3s var(--n-bezier);
 `)]),(0,v.cM)("active",[(0,v.cE)("rail","background-color: var(--n-rail-color-active);")]),(0,v.cM)("loading",[(0,v.cE)("rail",`
 cursor: wait;
 `)]),(0,v.cM)("disabled",[(0,v.cE)("rail",`
 cursor: not-allowed;
 opacity: .5;
 `)])]),k=Object.assign(Object.assign({},s.A.props),{size:String,value:{type:[String,Number,Boolean],default:void 0},loading:Boolean,defaultValue:{type:[String,Number,Boolean],default:!1},disabled:{type:Boolean,default:void 0},round:{type:Boolean,default:!0},"onUpdate:value":[Function,Array],onUpdateValue:[Function,Array],checkedValue:{type:[String,Number,Boolean],default:!0},uncheckedValue:{type:[String,Number,Boolean],default:!1},railStyle:Function,rubberBand:{type:Boolean,default:!0},spinProps:Object,onChange:[Function,Array]}),$=(0,o.pM)({name:"Switch",props:k,slots:Object,setup(e){void 0===n&&(n=!("u">typeof CSS)||void 0!==CSS.supports&&CSS.supports("width","max(1px)"));let{mergedClsPrefixRef:t,inlineThemeDisabled:i,mergedComponentPropsRef:l}=(0,d.Ay)(e),c=(0,s.A)("Switch","-switch",x,m,e,t),p=(0,u.A)(e,{mergedSize(t){var i,n;if(void 0!==e.size)return e.size;if(t)return t.mergedSize.value;let r=null==(n=null==(i=null==l?void 0:l.value)?void 0:i.Switch)?void 0:n.size;return r||"medium"}}),{mergedSizeRef:f,mergedDisabledRef:g}=p,w=(0,o.KR)(e.defaultValue),y=(0,o.lW)(e,"value"),k=(0,a.A)(y,w),$=(0,o.EW)(()=>k.value===e.checkedValue),E=(0,o.KR)(!1),B=(0,o.KR)(!1),z=(0,o.EW)(()=>{let{railStyle:t}=e;if(t)return t({focused:B.value,checked:$.value})});function C(t){let{"onUpdate:value":i,onChange:n,onUpdateValue:r}=e,{nTriggerFormInput:a,nTriggerFormChange:o}=p;i&&(0,b.T)(i,t),r&&(0,b.T)(r,t),n&&(0,b.T)(n,t),w.value=t,a(),o()}let S=(0,o.EW)(()=>{let e,t,i,{value:a}=f,{self:{opacityDisabled:o,railColor:l,railColorActive:s,buttonBoxShadow:d,buttonColor:u,boxShadowFocus:h,loadingColor:b,textColor:p,iconColor:g,[(0,v.cF)("buttonHeight",a)]:w,[(0,v.cF)("buttonWidth",a)]:m,[(0,v.cF)("buttonWidthPressed",a)]:y,[(0,v.cF)("railHeight",a)]:x,[(0,v.cF)("railWidth",a)]:k,[(0,v.cF)("railBorderRadius",a)]:$,[(0,v.cF)("buttonBorderRadius",a)]:E},common:{cubicBezierEaseInOut:B}}=c.value;return n?(e=`calc((${x} - ${w}) / 2)`,t=`max(${x}, ${w})`,i=`max(${k}, calc(${k} + ${w} - ${x}))`):(e=(0,r.Cw)(((0,r.eV)(x)-(0,r.eV)(w))/2),t=(0,r.Cw)(Math.max((0,r.eV)(x),(0,r.eV)(w))),i=(0,r.eV)(x)>(0,r.eV)(w)?k:(0,r.Cw)((0,r.eV)(k)+(0,r.eV)(w)-(0,r.eV)(x))),{"--n-bezier":B,"--n-button-border-radius":E,"--n-button-box-shadow":d,"--n-button-color":u,"--n-button-width":m,"--n-button-width-pressed":y,"--n-button-height":w,"--n-height":t,"--n-offset":e,"--n-opacity-disabled":o,"--n-rail-border-radius":$,"--n-rail-color":l,"--n-rail-color-active":s,"--n-rail-height":x,"--n-rail-width":k,"--n-width":i,"--n-box-shadow-focus":h,"--n-loading-color":b,"--n-text-color":p,"--n-icon-color":g}}),V=i?(0,h.R)("switch",(0,o.EW)(()=>f.value[0]),S,e):void 0;return{handleClick:function(){e.loading||g.value||(k.value!==e.checkedValue?C(e.checkedValue):C(e.uncheckedValue))},handleBlur:function(){B.value=!1,function(){let{nTriggerFormBlur:e}=p;e()}(),E.value=!1},handleFocus:function(){B.value=!0,function(){let{nTriggerFormFocus:e}=p;e()}()},handleKeyup:function(t){e.loading||g.value||" "===t.key&&(k.value!==e.checkedValue?C(e.checkedValue):C(e.uncheckedValue),E.value=!1)},handleKeydown:function(t){e.loading||g.value||" "===t.key&&(t.preventDefault(),E.value=!0)},mergedRailStyle:z,pressed:E,mergedClsPrefix:t,mergedValue:k,checked:$,mergedDisabled:g,cssVars:i?void 0:S,themeClass:null==V?void 0:V.themeClass,onRender:null==V?void 0:V.onRender}},render(){let{mergedClsPrefix:e,mergedDisabled:t,checked:i,mergedRailStyle:n,onRender:r,$slots:a}=this;null==r||r();let{checked:s,unchecked:d,icon:u,"checked-icon":h,"unchecked-icon":b}=a,v=!((0,p.yr)(u)&&(0,p.yr)(h)&&(0,p.yr)(b));return(0,o.h)("div",{role:"switch","aria-checked":i,class:[`${e}-switch`,this.themeClass,v&&`${e}-switch--icon`,i&&`${e}-switch--active`,t&&`${e}-switch--disabled`,this.round&&`${e}-switch--round`,this.loading&&`${e}-switch--loading`,this.pressed&&`${e}-switch--pressed`,this.rubberBand&&`${e}-switch--rubber-band`],tabindex:this.mergedDisabled?void 0:0,style:this.cssVars,onClick:this.handleClick,onFocus:this.handleFocus,onBlur:this.handleBlur,onKeyup:this.handleKeyup,onKeydown:this.handleKeydown},(0,o.h)("div",{class:`${e}-switch__rail`,"aria-hidden":"true",style:n},(0,p.iQ)(s,t=>(0,p.iQ)(d,i=>t||i?(0,o.h)("div",{"aria-hidden":!0,class:`${e}-switch__children-placeholder`},(0,o.h)("div",{class:`${e}-switch__rail-placeholder`},(0,o.h)("div",{class:`${e}-switch__button-placeholder`}),t),(0,o.h)("div",{class:`${e}-switch__rail-placeholder`},(0,o.h)("div",{class:`${e}-switch__button-placeholder`}),i)):null)),(0,o.h)("div",{class:`${e}-switch__button`},(0,p.iQ)(u,t=>(0,p.iQ)(h,i=>(0,p.iQ)(b,n=>(0,o.h)(l.A,null,{default:()=>this.loading?(0,o.h)(c.A,Object.assign({key:"loading",clsPrefix:e,strokeWidth:20},this.spinProps)):this.checked&&(i||t)?(0,o.h)("div",{class:`${e}-switch__button-icon`,key:i?"checked-icon":"icon"},i||t):!this.checked&&(n||t)?(0,o.h)("div",{class:`${e}-switch__button-icon`,key:n?"unchecked-icon":"icon"},n||t):null})))),(0,p.iQ)(s,t=>t&&(0,o.h)("div",{key:"checked",class:`${e}-switch__checked`},t)),(0,p.iQ)(d,t=>t&&(0,o.h)("div",{key:"unchecked",class:`${e}-switch__unchecked`},t)))))}})}}]);