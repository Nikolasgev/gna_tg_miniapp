import React, { useState } from 'react'
import Hero from './components/Hero'
import Features from './components/Features'
import HowItWorks from './components/HowItWorks'
import Pricing from './components/Pricing'
import Testimonials from './components/Testimonials'
import CTA from './components/CTA'
import Footer from './components/Footer'
import Navbar from './components/Navbar'
import ContactModal from './components/ContactModal'
import SEOHead from './components/SEOHead'

function App() {
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [selectedService, setSelectedService] = useState(null)

  const handleOpenModal = (service = null) => {
    setSelectedService(service)
    setIsModalOpen(true)
  }

  const handleCloseModal = () => {
    setIsModalOpen(false)
    setSelectedService(null)
  }

  return (
    <div className="min-h-screen">
      <SEOHead
        title="Telegram Mini App Store - Создайте интернет-магазин в Telegram за 5 минут"
        description="Полнофункциональная платформа для создания интернет-магазина в Telegram. Каталог товаров, онлайн-оплата YooKassa, доставка Яндекс.Доставка, админ-панель. Запуск за 5 минут без программирования."
        keywords="telegram mini app, интернет-магазин telegram, магазин в telegram, telegram bot магазин, создание магазина telegram, онлайн магазин, ecommerce telegram, телеграм магазин, мини приложение telegram, платформа для магазина"
        canonical="https://your-domain.com/"
      />
      <Navbar onOpenModal={() => handleOpenModal()} />
      <Hero onOpenModal={() => handleOpenModal()} />
      <Features />
      <HowItWorks onOpenModal={() => handleOpenModal()} />
      <Pricing onOpenModal={handleOpenModal} />
      <Testimonials />
      <CTA onOpenModal={() => handleOpenModal()} />
      <Footer />
      <ContactModal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        selectedService={selectedService}
      />
    </div>
  )
}

export default App


