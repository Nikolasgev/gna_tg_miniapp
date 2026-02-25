import React, { useState } from 'react'
import Navbar from './components/Navbar'
import Hero from './components/Hero'
import Features from './components/Features'
import AdminPanel from './components/AdminPanel'
import HowItWorks from './components/HowItWorks'
import Pricing from './components/Pricing'
import Testimonials from './components/Testimonials'
import CTA from './components/CTA'
import Footer from './components/Footer'
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
        title="Кофейня в Telegram - Создайте онлайн-магазин кофе за 5 минут"
        description="Полнофункциональная платформа для создания кофейни в Telegram. Каталог напитков, онлайн-оплата, доставка, админ-панель. Продавайте кофе, десерты и напитки через Telegram Mini App."
        keywords="кофейня telegram, магазин кофе telegram, кофе онлайн, telegram кофейня, мини приложение кофейня, доставка кофе, онлайн кофейня, telegram bot кофейня, кофейный бизнес, продажа кофе telegram"
        canonical="https://coffee.your-domain.com/"
      />
      <Navbar onOpenModal={() => handleOpenModal()} />
      <Hero onOpenModal={() => handleOpenModal()} />
      <Features />
      <AdminPanel />
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

