import { useEffect } from 'react'

/**
 * Компонент для динамического обновления meta тегов
 * Используется для SEO оптимизации
 */
const SEOHead = ({ title, description, keywords, ogImage, canonical }) => {
  useEffect(() => {
    // Обновляем title
    if (title) {
      document.title = title
    }

    // Обновляем meta description
    let metaDescription = document.querySelector('meta[name="description"]')
    if (!metaDescription) {
      metaDescription = document.createElement('meta')
      metaDescription.setAttribute('name', 'description')
      document.head.appendChild(metaDescription)
    }
    if (description) {
      metaDescription.setAttribute('content', description)
    }

    // Обновляем meta keywords
    let metaKeywords = document.querySelector('meta[name="keywords"]')
    if (!metaKeywords) {
      metaKeywords = document.createElement('meta')
      metaKeywords.setAttribute('name', 'keywords')
      document.head.appendChild(metaKeywords)
    }
    if (keywords) {
      metaKeywords.setAttribute('content', keywords)
    }

    // Обновляем Open Graph title
    let ogTitle = document.querySelector('meta[property="og:title"]')
    if (!ogTitle) {
      ogTitle = document.createElement('meta')
      ogTitle.setAttribute('property', 'og:title')
      document.head.appendChild(ogTitle)
    }
    if (title) {
      ogTitle.setAttribute('content', title)
    }

    // Обновляем Open Graph description
    let ogDescription = document.querySelector('meta[property="og:description"]')
    if (!ogDescription) {
      ogDescription = document.createElement('meta')
      ogDescription.setAttribute('property', 'og:description')
      document.head.appendChild(ogDescription)
    }
    if (description) {
      ogDescription.setAttribute('content', description)
    }

    // Обновляем Open Graph image
    if (ogImage) {
      let ogImageMeta = document.querySelector('meta[property="og:image"]')
      if (!ogImageMeta) {
        ogImageMeta = document.createElement('meta')
        ogImageMeta.setAttribute('property', 'og:image')
        document.head.appendChild(ogImageMeta)
      }
      ogImageMeta.setAttribute('content', ogImage)
    }

    // Обновляем canonical URL
    if (canonical) {
      let canonicalLink = document.querySelector('link[rel="canonical"]')
      if (!canonicalLink) {
        canonicalLink = document.createElement('link')
        canonicalLink.setAttribute('rel', 'canonical')
        document.head.appendChild(canonicalLink)
      }
      canonicalLink.setAttribute('href', canonical)
    }
  }, [title, description, keywords, ogImage, canonical])

  return null
}

export default SEOHead












