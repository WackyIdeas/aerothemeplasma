#include "../breezedecoration.h"
#include "../breezebutton.h"
#include "../frametexture.h"

#include <QLabel>
#include <QPainter>
#include <QPainterPath>
#include <QString>
#include <QPixmapCache>
#include <QRegularExpression>

#include <KDecoration3/DecorationButtonGroup>

namespace Breeze
{
static int g_sDecoCount = 0;
static std::shared_ptr<KDecoration3::DecorationShadow> g_smod_shadow, g_smod_shadow_unfocus;


Decoration::Decoration(QObject *parent, const QVariantList &args)
: KDecoration3::Decoration(parent, args)
, m_animation(new QVariantAnimation(this))
, m_shadowAnimation(new QVariantAnimation(this))
{
    g_sDecoCount++;
}

Decoration::~Decoration()
{
    g_sDecoCount--;
    if (g_sDecoCount == 0) {
        // last deco destroyed, clean up shadow
        g_smod_shadow.reset();
        g_smod_shadow_unfocus.reset();
    }
}
int Decoration::decorationCount()
{
    return g_sDecoCount;
}
void Decoration::updateShadow(bool reconfigured)
{
    if(reconfigured)
    {
        g_smod_shadow.reset();
        g_smod_shadow_unfocus.reset();
    }
    if(!internalSettings()->enableShadow())
    {
        setShadow(std::shared_ptr<KDecoration3::DecorationShadow>(nullptr));
        return;
    }
    if (window()->isActive())
    {
        g_smod_shadow = g_smod_shadow ? g_smod_shadow : smodCreateShadow(true);
        setShadow(g_smod_shadow);
    }
    else
    {
        g_smod_shadow_unfocus = g_smod_shadow_unfocus ? g_smod_shadow_unfocus : smodCreateShadow(false);
        setShadow(g_smod_shadow_unfocus);
    }

}
std::shared_ptr<KDecoration3::DecorationShadow> Decoration::smodCreateShadow(bool active)
{
    QImage shadowTexture = QImage(active ? ":/smod/decoration/shadow" : ":/smod/decoration/shadow-unfocus");
    auto margins = sizingMargins().shadowSizing();
    QMargins texMargins(margins.margin_left, margins.margin_top, margins.margin_right, margins.margin_bottom);
    QMargins padding(margins.padding_left, margins.padding_top, margins.padding_right, margins.padding_bottom);
    QRect innerShadowRect = shadowTexture.rect() - texMargins;

    auto shadow = std::make_shared<KDecoration3::DecorationShadow>();
    shadow->setPadding(padding);
    shadow->setInnerShadowRect(innerShadowRect);
    shadow->setShadow(shadowTexture);
    return shadow;
}

void Decoration::updateBlur()
{
    auto margins = sizingMargins().commonSizing();
    const int radius = isMaximized() ? 0 : margins.corner_radius+1;

    QPainterPath path;
    path.addRoundedRect(rect(), radius, radius);

    setBlurRegion(QRegion(path.toFillPolygon().toPolygon()));

    updateShadow();
}

void Decoration::smodPaint(QPainter *painter, const QRectF &repaintRegion)
{
    painter->fillRect(rect(), Qt::transparent);

    smodPaintOuterBorder(painter, repaintRegion);
    //smodPaintInnerBorder(painter, repaintRegion);
    smodPaintGlow(painter, repaintRegion);
    smodPaintTitleBar(painter, repaintRegion);
}

void Decoration::smodPaintGlow(QPainter *painter, const QRectF &repaintRegion)
{
    const auto c = window();

    int SIDEBAR_HEIGHT = qMax(25, (int)(size().height() / 4));
    if(internalSettings()->invertTextColor() && isMaximized()) return;
    painter->setClipRegion(blurRegion());
    painter->setClipping(true);
    if(!isMaximized() && !hideInnerBorder())
    {
        auto margins_left = sizingMargins().frameLeftSizing();
        auto margins_right = sizingMargins().frameRightSizing();
        QPixmap sidehighlight(":/smod/decoration/sidehighlight" + (!c->isActive() ? QString("-unfocus") : QString("")));
        painter->drawPixmap(margins_left.inset, borderTop(), borderLeft() - margins_left.inset - margins_left.inset, SIDEBAR_HEIGHT, sidehighlight);
        painter->drawPixmap(size().width() - borderRight() + margins_right.inset, borderTop(), borderRight() - margins_right.inset - margins_right.inset, SIDEBAR_HEIGHT, sidehighlight);
    }
    painter->setClipping(false);
}
void Decoration::smodPaintOuterBorder(QPainter *painter, const QRectF &repaintRegion)
{
    Q_UNUSED(repaintRegion);
    bool active = window()->isActive();
    QString    s_top(":/smod/decoration/top");
    QString   s_left(":/smod/decoration/left");
    QString  s_right(":/smod/decoration/right");
    QString s_bottom(":/smod/decoration/bottom");
    QString  unfocus("_unfocus");
    QString noshadow("_noshadow");
    QString noinner("_noinner");

    if(!internalSettings()->enableShadow())
    {
        s_top    += noshadow;
        s_bottom += noshadow;
    }
    if(!active)
    {
        s_top    += unfocus;
        s_bottom += unfocus;
        s_left   += unfocus;
        s_right  += unfocus;
    }
    if(hideInnerBorder())
    {
        s_top    += noinner;
        s_bottom += noinner;
        s_left   += noinner;
        s_right  += noinner;
    }

    // Render the top side, which is always visible
    QPixmap p_top(s_top);
    auto t_m = sizingMargins().topSide();
    auto l_m = sizingMargins().leftSide();
    auto r_m = sizingMargins().rightSide();
    auto b_m = sizingMargins().bottomSide();
    auto tl_m = sizingMargins().topLeftCorner();
    auto tr_m = sizingMargins().topRightCorner();

    qreal modBorderLeft = borderLeft() + (hideInnerBorder() ? l_m.margin_right : 0);
    qreal modBorderRight = borderRight() + (hideInnerBorder() ? r_m.margin_left : 0);
    qreal modBorderTop = borderTop() + (hideInnerBorder() ? t_m.margin_bottom : 0);
    qreal modBorderBottom = borderBottom() + (hideInnerBorder() ? b_m.margin_top : 0);

    FrameTexture top(0, 0,
                     isMaximized() ? 0 : t_m.margin_top,
                     t_m.margin_bottom,
                     isMaximized() ? (size().width() - borderLeft() - borderRight()) : (size().width() - modBorderLeft - modBorderRight),
                     isMaximized() ? borderTop() : modBorderTop,
                     &p_top,
                     1.0,
                     false,
                     tl_m.width, isMaximized() ? t_m.margin_top : 0,
                     p_top.width() - tl_m.width - tr_m.width, p_top.height() - (isMaximized() ? t_m.margin_top : 0));
    top.translate(isMaximized() ? borderLeft() : modBorderLeft, 0);
    top.render(painter);

    if(!isMaximized()) // Render the rest of the decoration
    {
        QPixmap p_left(s_left);
        QPixmap p_right(s_right);
        QPixmap p_bottom(s_bottom);

        auto bl_m = sizingMargins().bottomLeftCorner();
        auto br_m = sizingMargins().bottomRightCorner();

        // Corners
        FrameTexture     topleft(tl_m.margin_left,
                                 tl_m.margin_right,
                                 tl_m.margin_top,
                                 tl_m.margin_bottom,
                                 modBorderLeft,
                                 modBorderTop,
                                 &p_top,
                                 1.0,
                                 false,
                                 0, 0, tl_m.width, p_top.height());

        FrameTexture    topright(tr_m.margin_left,
                                 tr_m.margin_right,
                                 tr_m.margin_top,
                                 tr_m.margin_bottom,
                                 modBorderRight,
                                 modBorderTop,
                                 &p_top,
                                 1.0,
                                 false,
                                 p_top.width()-tr_m.width, 0,
                                 tr_m.width, p_top.height());

        FrameTexture  bottomleft(bl_m.margin_left,
                                 bl_m.margin_right,
                                 bl_m.margin_top,
                                 bl_m.margin_bottom,
                                 modBorderLeft,
                                 modBorderBottom,
                                 &p_bottom,
                                 1.0,
                                 false,
                                 0, 0,
                                 bl_m.width, p_bottom.height());

        FrameTexture bottomright(br_m.margin_left,
                                 br_m.margin_right,
                                 br_m.margin_top,
                                 br_m.margin_bottom,
                                 modBorderRight,
                                 modBorderBottom,
                                 &p_bottom,
                                 1.0,
                                 false,
                                 p_bottom.width()-br_m.width, 0,
                                 br_m.width, p_bottom.height());
        // Sides
        FrameTexture        left(l_m.margin_left,
                                 l_m.margin_right,
                                 0, 0,
                                 modBorderLeft,
                                 size().height()-modBorderBottom-modBorderTop,
                                 &p_left);

        FrameTexture       right(r_m.margin_left,
                                 r_m.margin_right,
                                 0, 0,
                                 modBorderRight,
                                 size().height()-modBorderBottom-modBorderTop,
                                 &p_right);

        FrameTexture      bottom(0, 0,
                                 b_m.margin_top,
                                 b_m.margin_bottom,
                                 size().width() - modBorderLeft - modBorderRight, modBorderBottom,
                                 &p_bottom,
                                 1.0,
                                 false,
                                 bl_m.width, 0,
                                 p_bottom.width() - bl_m.width - br_m.width, p_bottom.height());

        // Move texture fragments to the appropriate locations
        topright.translate(size().width() - modBorderRight, 0);
        bottomleft.translate(0, size().height() - modBorderBottom);
        bottomright.translate(size().width() - modBorderRight, size().height() - modBorderBottom);
        left.translate(0, modBorderTop);
        right.translate(size().width()-modBorderRight, modBorderTop);
        bottom.translate(modBorderLeft, size().height() - modBorderBottom);
        // Render them all
        topleft.render(painter);
        topright.render(painter);
        bottomleft.render(painter);
        bottomright.render(painter);
        left.render(painter);
        right.render(painter);
        bottom.render(painter);
    }
}

void Decoration::smodPaintTitleBar(QPainter *painter, const QRectF &repaintRegion)
{
    if (hideTitleBar())
    {
        return;
    }

    if (!hideCaption())
    {
        const auto c = window();
        int titleAlignment = internalSettings()->titleAlignment();
        bool invertText = internalSettings()->invertTextColor() && c->isMaximized();

        QRect captionRect(m_leftButtons->geometry().right(), 0, m_rightButtons->geometry().left() - m_leftButtons->geometry().right() - 4, borderTop() + (hideInnerBorder() ? sizingMargins().topSide().margin_bottom : 0));
        QString caption = settings()->fontMetrics().elidedText(c->caption(), Qt::ElideMiddle, captionRect.width());
        QStringList programname = caption.split(" — ");
        caption.remove(" — " + programname.at(programname.size()-1));
        QFontMetrics fm(settings()->font());
        QString fixedCaption = caption;
        auto rect = fm.boundingRect(fixedCaption.replace(QRegularExpression("\\p{Extended_Pictographic}", QRegularExpression::UseUnicodePropertiesOption), "█"));
        int blurWidth = rect.width() + 30;
        int blurHeight = rect.height();

        QColor shadowColor = QColor(0, 0, 0, 255);
        QColor textColor = c->color(c->isActive() ? KDecoration3::ColorGroup::Active : KDecoration3::ColorGroup::Inactive, KDecoration3::ColorRole::Foreground);

        captionRect.setHeight(captionRect.height() & -2);
        painter->setFont(settings()->font());
        painter->setPen(shadowColor);
        painter->setPen(textColor);

        QLabel real_label(caption);
        QPalette palette = real_label.palette();
        if(invertText)
        {
            textColor.setRed(255-textColor.red());
            textColor.setGreen(255-textColor.green());
            textColor.setBlue(255-textColor.blue());
        }
        palette.setColor(real_label.backgroundRole(), textColor);
        palette.setColor(real_label.foregroundRole(), textColor);
        real_label.setStyleSheet("QLabel { background: #00aaaaaa; }");
        real_label.setPalette(palette);
        auto f = settings()->font();
        f.setKerning(false);
        if(invertText) f.setWeight(QFont::DemiBold);
        real_label.setFont(f);
        real_label.setFixedWidth(captionRect.width());
        real_label.setFixedHeight(captionRect.height());

        if(titleAlignment == InternalSettings::AlignRight)
            real_label.setAlignment(Qt::AlignRight);
        else if(titleAlignment == InternalSettings::AlignCenter)
            real_label.setAlignment(Qt::AlignHCenter);
        else if(titleAlignment == InternalSettings::AlignCenterFullWidth)
        {
            real_label.setFixedWidth(size().width());
            real_label.setAlignment(Qt::AlignHCenter);
        }

        QPixmap glow(":/smod/decoration/glow");
        auto margins = sizingMargins().glowSizing();
        int l = margins.margin_left;
        int r = margins.margin_right;
        int t = margins.margin_top;
        int b = margins.margin_bottom;
        painter->setRenderHint(QPainter::Antialiasing, true);
        painter->setRenderHint(QPainter::SmoothPixmapTransform, true);

        int glowHeight = blurHeight*1.5;
        int glowWidth = blurWidth + 8;
        if(glowWidth < l+r)
        {
            glowWidth = l+r;
            //l -= (l+r) - glowWidth;
        }
        if(glowHeight < t+b)
        {
            glowHeight = t+b;
            //t -= (t+b) - glowHeight;
        }


        FrameTexture gl(l, r, t, b, glowWidth, glowHeight, &glow, c->isActive() ? margins.active_opacity : margins.inactive_opacity);

        int leftButtonsX = (hideIcon() ? -5 : m_leftButtons->geometry().x());

        if(!caption.trimmed().isEmpty())
        {
            if(titleAlignment == InternalSettings::AlignCenterFullWidth)
            {
                captionRect.setX(0);
                captionRect.setWidth(size().width());
            }
            float xpos = captionRect.x();
            if(titleAlignment == InternalSettings::AlignRight)
            {
                xpos += captionRect.width() - blurWidth;
            }
            else if(titleAlignment == InternalSettings::AlignCenter || titleAlignment == InternalSettings::AlignCenterFullWidth)
            {
                xpos += captionRect.width()/2 - blurWidth/2;
            }
            else
            {
                xpos = leftButtonsX + 2;
            }

            bool isRTL = caption.isRightToLeft();
            auto fixedAlignment = titleAlignment;
            if(isRTL)
            {
                if(fixedAlignment == InternalSettings::AlignRight)
                {
                    fixedAlignment = InternalSettings::AlignLeft;
                    xpos = leftButtonsX + 2;
                }
                else if(fixedAlignment == InternalSettings::AlignLeft)
                {
                    fixedAlignment = InternalSettings::AlignRight;
                    xpos += captionRect.width() - blurWidth;
                }
            }
            if(!invertText)
            {
                int alignmentOffset = 0;
                if(fixedAlignment == InternalSettings::AlignCenter || fixedAlignment == InternalSettings::AlignCenterFullWidth)
                {
                    alignmentOffset = -4;
                    if(m_rightButtons->geometry().intersects(QRect(xpos + alignmentOffset, captionRect.height() / 2 - blurHeight - 2, glowWidth, glowHeight)))
                    {
                        captionRect.setX(leftButtonsX);
                        captionRect.setWidth(size().width() - m_rightButtons->geometry().width());
                        real_label.setFixedWidth(captionRect.width());
                        xpos = captionRect.x();
                        xpos += captionRect.width()/2 - blurWidth/2;
                    }
                }
                else if(fixedAlignment == InternalSettings::AlignRight)
                {
                    alignmentOffset = -2;
                }

                if(isRTL && titleAlignment == InternalSettings::AlignLeft)
                {
                    alignmentOffset += 16;
                }

                painter->translate(xpos + alignmentOffset, (captionRect.height() - glowHeight) / 2);
                gl.render(painter);
                painter->translate(-xpos - alignmentOffset, (-captionRect.height() + glowHeight) / 2);

            }
            QPixmap text_pixmap = real_label.grab();

            if(fixedAlignment == InternalSettings::AlignRight)
            {
                captionRect.translate(-12, -1);
            }
            else if(fixedAlignment == InternalSettings::AlignLeft)
            {
                captionRect.translate(5, -1);
            }
            else if(fixedAlignment == InternalSettings::AlignCenterFullWidth || fixedAlignment == InternalSettings::AlignCenter)
            {
                captionRect.translate(1, -1);
            }
            painter->drawPixmap(captionRect, text_pixmap);
            if(invertText)
            {
                painter->setOpacity(0.7);
                painter->drawPixmap(captionRect, text_pixmap);
                painter->setOpacity(1.0);
                //painter->drawPixmap(captionRect, text_pixmap);
            }
        }
    }

    m_leftButtons->paint(painter, repaintRegion);
    m_rightButtons->paint(painter, repaintRegion);

    /*foreach (QPointer<KDecoration3::DecorationButton> button, m_rightButtons->buttons()) {
        static_cast<Button *>(button.data())->smodPaintGlow(painter, repaintRegion);
    }*/
}

}
