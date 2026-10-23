#import "PinyinSegmenter.h"

// The closed pinyin syllable inventory: the union of CC-CEDICT and the shipped
// luna_pinyin dictionary, minus single-letter abbreviations (only a, e, o are
// syllables on their own).
static NSString *const kSyllables = @"a ai an ang ao ba bai ban bang bao bei ben beng bi bian biang biao bie bin bing bo bu ca cai can "
                                    @"cang cao ce cei cen ceng cha chai chan chang chao che chen cheng chi chong chou chu chua chuai "
                                    @"chuan chuang chui chun chuo ci cong cou cu cuan cui cun cuo da dai dan dang dao de dei den deng "
                                    @"di dia dian diao die din ding diu dong dou du duan dui dun duo e eh ei en eng er fa fan fang fei "
                                    @"fen feng fiao fo fong fou fu ga gai gan gang gao ge gei gen geng gong gou gu gua guai guan guang "
                                    @"gui gun guo ha hai han hang hao he hei hen heng hong hou hu hua huai huan huang hui hun huo ji "
                                    @"jia jian jiang jiao jie jin jing jiong jiu ju juan jue jun ka kai kan kang kao ke kei ken keng "
                                    @"kong kou ku kua kuai kuan kuang kui kun kuo la lai lan lang lao le lei leng li lia lian liang "
                                    @"liao lie lin ling liu lo long lou lu luan lue lun luo lv lvan lve ma mai man mang mao me mei men "
                                    @"meng mi mian miao mie min ming miu mo mou mu na nai nan nang nao ne nei nen neng ni nia nian "
                                    @"niang niao nie nin ning niu nong nou nu nuan nue nun nuo nv nve o ou pa pai pan pang pao pei pen "
                                    @"peng pi pia pian piao pie pin ping po pou pu qi qia qian qiang qiao qie qin qing qiong qiu qu "
                                    @"quan que qun ran rang rao re ren reng ri rong rou ru rua ruan rui run ruo sa sai san sang sao se "
                                    @"sei sen seng sha shai shan shang shao she shei shen sheng shi shou shu shua shuai shuan shuang "
                                    @"shui shun shuo si song sou su suan sui sun suo ta tai tan tang tao te tei teng ti tian tiao tie "
                                    @"ting tong tou tu tuan tui tun tuo wa wai wan wang wei wen weng wo wong wu xi xia xian xiang xiao "
                                    @"xie xin xing xiong xiu xu xuan xue xun ya yai yan yang yao ye yi yin ying yo yong you yu yuan "
                                    @"yue yun za zai zan zang zao ze zei zen zeng zha zhai zhan zhang zhao zhe zhei zhen zheng zhi "
                                    @"zhong zhou zhu zhua zhuai zhuan zhuang zhui zhun zhuo zi zong zou zu zuan zui zun zuo";

// Integer constants (not `static const NSUInteger`, which is not a constant
// expression and would make dp below a VLA).
enum {
    kMaxSyllableLength = 6, // zhuang, chuang
    kMaxInputLength = 64,
};

@implementation PinyinSegmenter

+ (BOOL)canFullySegment:(NSString *)input {
    static NSSet<NSString *> *syllables;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        syllables = [NSSet setWithArray:[kSyllables componentsSeparatedByString:@" "]];
    });

    NSUInteger length = input.length;
    if (length == 0 || length > kMaxInputLength) {
        return NO;
    }

    // dp[i]: the first i characters split into complete syllables
    BOOL dp[kMaxInputLength + 1];
    dp[0] = YES;
    for (NSUInteger i = 1; i <= length; i++) {
        dp[i] = NO;
        NSUInteger start = i > kMaxSyllableLength ? i - kMaxSyllableLength : 0;
        for (NSUInteger j = start; j < i && !dp[i]; j++) {
            if (dp[j] && [syllables containsObject:[input substringWithRange:NSMakeRange(j, i - j)]]) {
                dp[i] = YES;
            }
        }
    }
    return dp[length];
}

@end
